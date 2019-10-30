using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace ACT.Hojoring.ATDExtractor
{
    /// <summary>
    /// MainWindow.xaml の相互作用ロジック
    /// </summary>
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
            textBox.AddHandler(TextBox.DragOverEvent, new DragEventHandler(TextBox_DragOver), true);
            textBox.AddHandler(TextBox.DropEvent, new DragEventHandler(TextBox_Drop), true);
        }

        private void TextBox_DragOver(object sender, DragEventArgs e)
        {
            if (e.Data.GetDataPresent(DataFormats.FileDrop))
            {
                e.Effects = DragDropEffects.All;
            }
            else
            {
                e.Effects = DragDropEffects.None;
            }
            e.Handled = false;
        }

        private void TextBox_Drop(object sender, DragEventArgs e)
        {
            if (e.Data.GetDataPresent(DataFormats.FileDrop))
            {
                textBox.Text = string.Empty;
                string[] files = (string[])e.Data.GetData(DataFormats.FileDrop);

                var res = App.ExtractATD(files);
                if(res)
                {
                    textBox.Text = "AquesTalkDriver.dll を抽出しました。";
                }
                else
                {
                    textBox.Text = "AquesTalkDriver.dll は見つかりませんでした。";
                }

            }
        }
    }
}
