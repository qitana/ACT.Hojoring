using System;
using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Threading;

namespace ACT.Hojoring.Common
{
    public class Hojoring
    {
#if ENABLE_SPLASH_SCREEN
        private static volatile bool isSplashShown = false;
#else
        private static volatile bool isSplashShown = true;
#endif

        public Version Version => Assembly.GetExecutingAssembly().GetName().Version;

        public async void ShowSplash()
        {
            if (isSplashShown)
            {
                return;
            }

            isSplashShown = true;

            var dir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
            if (Directory.GetFiles(
                dir,
                "*NOSPLASH*",
                SearchOption.TopDirectoryOnly).Length > 0)
            {
                return;
            }

            await Application.Current.Dispatcher.InvokeAsync(
                () =>
                {
                    var window = new SplashWindow();
                    window.Loaded += (_, __) => window.StartFadeOut();
                    window.Show();
                    window.Activate();
                },
                DispatcherPriority.Normal);
        }
    }
}
