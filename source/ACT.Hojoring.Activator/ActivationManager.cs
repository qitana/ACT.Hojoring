using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net;
using System.Net.Cache;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using ACT.Hojoring.Activator.Models;
using Advanced_Combat_Tracker;

namespace ACT.Hojoring.Activator
{
    public class ActivationManager
    {
        #region Lazy Singleton

        private static readonly Lazy<ActivationManager> LazyInstance = new Lazy<ActivationManager>(() => new ActivationManager());

        public static ActivationManager Instance => LazyInstance.Value;

        private ActivationManager()
        {
            Logger.Instance.Write("activator init.");
        }

        #endregion Lazy Singleton

        private static readonly object LockObject = new object();

        private static readonly double[] FuzzyIntervals = new[]
        {
            0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1.0, 1.05, 1.1, 1.15, 1.2, 1.25
        };

        private static double GetFuzzy() => FuzzyIntervals.OrderBy(x => Guid.NewGuid()).FirstOrDefault();

        private readonly Lazy<System.Timers.Timer> LazyTimer = new Lazy<System.Timers.Timer>(() =>
        {
            var timer = new System.Timers.Timer(TimeSpan.FromMinutes(60 * GetFuzzy()).TotalMilliseconds);

            timer.AutoReset = true;
            timer.Elapsed += (_, __) =>
            {
                if (!ActGlobals.oFormActMain.InitActDone)
                {
                    return;
                }

                RefreshAccountList();
                timer.Interval = TimeSpan.FromMinutes(60 * GetFuzzy()).TotalMilliseconds;
            };

            return timer;
        });

        public ActivationStatus CurrentStatus { get; private set; } = ActivationStatus.Loading;

        private Func<bool> isBusyCallback;

        private bool isStarted = false;

        public void Start(
            Func<bool> isBusyCallback = null)
        {
            lock (LockObject)
            {
                if (this.isStarted)
                {
                    return;
                }

                this.isStarted = true;

                if (this.LazyTimer.Value.Enabled)
                {
                    return;
                }

                ServicePointManager.DefaultConnectionLimit = 32;
                ServicePointManager.SecurityProtocol &= ~SecurityProtocolType.Tls;
                ServicePointManager.SecurityProtocol &= ~SecurityProtocolType.Tls11;
                ServicePointManager.SecurityProtocol |= SecurityProtocolType.Tls12;

                if (isBusyCallback != null)
                {
                    this.isBusyCallback = isBusyCallback;
                }

                Task.Run(async () =>
                {
                    if (this.LazyTimer.Value.Enabled)
                    {
                        return;
                    }

                    while (!ActGlobals.oFormActMain.InitActDone)
                    {
                        await Task.Delay(300);
                    }

                    await Task.Delay(TimeSpan.FromMinutes(1));

                    this.LazyTimer.Value.Start();
                    RefreshAccountList();
                });
            }
        }

        private DateTime activationTimestamp = DateTime.Now;
        private string activationAccount = string.Empty;

        public Action ActivationDeniedCallback { get; set; }

        public bool TryActivation(
            string name,
            string server,
            string guild)
        {
            var now = DateTime.Now;
            var account = $"{name}-{server}-{guild}";

            if (this.activationAccount != account ||
                (this.activationTimestamp - now).TotalMinutes > (60 * GetFuzzy()))
            {
                this.activationAccount = account;
                this.EnqueueActivation(name, server, guild);

                if (this.CurrentStatus != ActivationStatus.Loading)
                {
                    this.activationTimestamp = now;
                }
            }

            switch (this.CurrentStatus)
            {
                case ActivationStatus.Loading:
                case ActivationStatus.Allow:
                    return true;

                default:
                    this.ActivationDeniedCallback?.Invoke();
                    return false;
            }
        }

        private void EnqueueActivation(
            string name,
            string server,
            string guild)
        {
            switch (this.CurrentStatus)
            {
                case ActivationStatus.Loading:
                case ActivationStatus.Error:
                    return;
            }

            var list = default(IEnumerable<Account>);
            lock (LockObject)
            {
                list = AccountList.Instance.CurrentList?.ToArray();
            }

            if (list == null ||
                !list.Any())
            {
                Logger.Instance.Write("error, account list is empty.");
                return;
            }

            Task.Run(() =>
            {
                var isMatch = false;
                var sw = Stopwatch.StartNew();

                try
                {
                    foreach (var account in list)
                    {
                        isMatch = account.IsMatch(name, server, guild, currentSalt);
                        Thread.Sleep(1);
                    }
                }
                finally
                {
                    sw.Stop();
                    Logger.Instance.Write($"account verified. count={list.Count()} duration={sw.Elapsed.TotalSeconds:F0}");
                }

                this.CurrentStatus = isMatch ? ActivationStatus.Deny : ActivationStatus.Allow;

                Logger.Instance.Write(
                    $"n={name} s={server} g={guild} is {(!isMatch ? "allow" : "deny")}.");
            });
        }

        private static volatile string currentSalt;

        private static async void RefreshAccountList()
        {
            if (Instance.isBusyCallback?.Invoke() ?? true)
            {
                return;
            }

            try
            {
                var json = string.Empty;
                var salt = default(string);

                for (int i = 0; i < 3; i++)
                {
                    try
                    {
                        using (var client = new HttpClient(new WebRequestHandler()
                        {
                            CachePolicy = new HttpRequestCachePolicy(HttpRequestCacheLevel.NoCacheNoStore),
                        }))
                        {
                            client.DefaultRequestHeaders.UserAgent.ParseAdd("Hojoring/1.0");
                            client.Timeout = TimeSpan.FromSeconds(90);

                            json = await client.GetStringAsync(AccountListUrl);
                            salt = await client.GetStringAsync(AccountSaltUrl);
                        }

                        break;
                    }
                    catch (TaskCanceledException ex)
                    {
                        if (i <= 1)
                        {
                            Logger.Instance.Write("download task canceled. retring download...");
                        }
                        else
                        {
                            Logger.Instance.Write("download task canceled.", ex.InnerException ?? ex);
#if ENABLE_ACTIVATOR
                            ActivationManager.Instance.CurrentStatus = ActivationStatus.Error;
#else
                            ActivationManager.Instance.CurrentStatus = ActivationStatus.Allow;
#endif
                            return;
                        }
                    }
                }

                lock (LockObject)
                {
                    AccountList.Instance.Load(json);
                    currentSalt = salt;
                }

                ActivationManager.Instance.CurrentStatus = ActivationStatus.Allow;
                Logger.Instance.Write("account list refreshed.");
            }
            catch (Exception ex)
            {
#if ENABLE_ACTIVATOR
                ActivationManager.Instance.CurrentStatus = ActivationStatus.Error;
#else
                ActivationManager.Instance.CurrentStatus = ActivationStatus.Allow;
#endif
                Logger.Instance.Write("error on acount list download.", ex);
            }
        }

#if ENABLE_ACTIVATOR
        private static readonly string AccountListUrl
            = "https://gist.githubusercontent.com/anoyetta/bc658cb51552ea12ce1aaa2899004e8c/raw/accounts.json";

        private static readonly string AccountSaltUrl
            = "https://gist.githubusercontent.com/anoyetta/bc658cb51552ea12ce1aaa2899004e8c/raw/accounts_salt.txt";
#else
        private static readonly string AccountListUrl
            = "https://gist.githubusercontent.com/qitana/7e9cbf584f9944da70806daca370f23c/raw/accounts.json";

        private static readonly string AccountSaltUrl
            = "https://gist.githubusercontent.com/qitana/7e9cbf584f9944da70806daca370f23c/raw/accounts_salt.txt";
#endif
    }

    public enum ActivationStatus
    {
        Loading,
        Error,
        Allow,
        Deny,
    }
}
