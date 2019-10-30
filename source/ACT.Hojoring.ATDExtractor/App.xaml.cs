using System;
using System.IO;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Linq;
using System.Threading.Tasks;
using System.Windows;

namespace ACT.Hojoring.ATDExtractor
{
    /// <summary>
    /// App.xaml の相互作用ロジック
    /// </summary>
    public partial class App : Application
    {
        private void Application_Startup(object sender, StartupEventArgs e)
        {
            List<string> files = System.Environment.GetCommandLineArgs().ToList();
            if(files.Count > 1)
            {
                files.RemoveAt(0);
                ExtractATD(files.ToArray());
                this.Shutdown();
            }
            else
            {
                MainWindow window = new MainWindow();
                window.Show();
            }
        }

        public static bool ExtractATD(string[] files)
        {
            string appDir = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);
            string extractDir = Path.Combine(appDir, "AquesTalkDriver");
            string[] resourceNames = { "costura32.aquestalkdriver.dll", "costura64.aquestalkdriver.dll" };

            bool found = false;
            foreach (var file in files)
            {
                if (File.Exists(file))
                {
                    if (file.EndsWith(".dll"))
                    {
                        if (!Directory.Exists(extractDir))
                        {
                            Directory.CreateDirectory(extractDir);
                        }

                        foreach (var resouceName in resourceNames)
                        {
                            var res = CosturaDecompress.SaveResouceFromAssembly(file, resouceName, Path.Combine(extractDir, "AquesTalkDriver.dll"));
                            if (res > 0) found = true;
                            if (found) break;
                        }
                    }
                }
                if (found) break;
            }

            return found;

        }
    }
}
