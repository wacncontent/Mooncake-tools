using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Windows.Forms;
using System.Text.RegularExpressions;
using Newtonsoft.Json;

namespace GithubComparer
{
    public partial class Form1 : Form
    {
        // Regex Patterns
        const string MS_DATE_PATTERN = "ms.date=\"(.*?)\"";
        const string WACN_DATE_PATTERN = "wacn.date=\"(.*?)\"";

        // Instantiate the regular expression object.
        Regex msPattern  = new Regex(MS_DATE_PATTERN, RegexOptions.IgnoreCase);
        Regex wacnPattern = new Regex(WACN_DATE_PATTERN, RegexOptions.IgnoreCase);

        private Dictionary<string, string> _acomFileDate = new Dictionary<string, string>();
        private Dictionary<string, DataStore> _wacnFileDate = new Dictionary<string, DataStore>();

        public Form1()
        {
            InitializeComponent();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            FolderBrowserDialog fbd = new FolderBrowserDialog();
            if (DialogResult.OK == fbd.ShowDialog())
            {
                textBox1.Text = fbd.SelectedPath;
            }
        }

        private void button2_Click(object sender, EventArgs e)
        {
            FolderBrowserDialog fbd = new FolderBrowserDialog();
            if (DialogResult.OK == fbd.ShowDialog())
            {
                textBox2.Text = fbd.SelectedPath;
            }
        }

        private void button3_Click(object sender, EventArgs e)
        {
            try
            {
                // Ignore list
                List<Ignore> ignoreList = new List<Ignore>();

                Dictionary<string, Dictionary<string, ArrayList>> dictionary = JsonConvert.DeserializeObject<Dictionary<string, Dictionary<string, ArrayList>>>(File.ReadAllText(@"ignore.json"));

                foreach (KeyValuePair<string, Dictionary<string, ArrayList>> kv in dictionary)
                {
                    Ignore ignore = new Ignore();

                    ignore.section = kv.Key;
                    ignore.directoryList = kv.Value["directory"];
                    ignore.fileList = kv.Value["file"];
                    ignoreList.Add(ignore);
                }

                GetFileListDateFrom815(new DirectoryInfo(textBox1.Text), _wacnFileDate, ignoreList[0]);
                GetFileListDateFromACOM(new DirectoryInfo(textBox2.Text), _acomFileDate, ignoreList[1]);

                foreach (var item in _wacnFileDate)
                {
                    if (_acomFileDate.Keys.Contains(item.Key))
                    {
                        item.Value.ACOMDate = _acomFileDate[item.Key];
                    }
                }

                PrintResult(_wacnFileDate);

                MessageBox.Show("Done!");
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error:" + ex.Message);
            }
        }

        private void PrintResult(Dictionary<string, DataStore> _wacnFileDate)
        {
            string format = "{0},{1},{2},{3}";
            using (StreamWriter sw = new StreamWriter("result.csv"))
            {
                sw.WriteLine(string.Format(format, "URL", "ACOMDate(Lastest)", "ACOMDate", "WACNDate"));
                foreach (var item in _wacnFileDate)
                {
                    sw.WriteLine(string.Format(format, item.Value.URL, item.Value.ACOMDate, item.Value.ACOMDateWACN, item.Value.WACNDate));
                }
            }
        }

        private void GetFileListDateFromACOM(DirectoryInfo folder, Dictionary<string, string> result, Ignore ignore)
        {
            FileInfo[] allFiles = folder.GetFiles("*.md");

            foreach (var file in allFiles)
            {
                // check if dismissed directory or files
                if(ignore.fileList.Contains(file.Name))
                {
                    continue;
                }
                else
                {
                    using (StreamReader sr = file.OpenText())
                    {
                        string text = sr.ReadToEnd();

                        Match acomMatch = msPattern.Match(text);
                        // Found ms.date
                        if (acomMatch.Success)
                        {
                            // extract date out
                            result[file.Name] = acomMatch.Groups[1].Value;
                        }
                    }
                }
            }

            DirectoryInfo[] allDir = folder.GetDirectories();

            foreach (var directory in allDir)
            {
                if (ignore.directoryList.Contains(directory.Name))
                {
                    continue;
                }
                else
                {
                    GetFileListDateFromACOM(directory, result, ignore);
                }
            }
        }

        private void GetFileListDateFrom815(DirectoryInfo folder, Dictionary<string, DataStore> result, Ignore ignore)
        {
            FileInfo[] allFiles = folder.GetFiles("*.md");

            foreach (var file in allFiles)
            {
                // check if dismissed directory or files
                if (ignore.fileList.Contains(file.Name))
                {
                    continue;
                }

                else
                {
                    DataStore ds = new DataStore();

                    using (StreamReader sr = file.OpenText())
                    {
                        string text = sr.ReadToEnd();

                        // Match the wacn.date and ms.date
                        Match wacnMatch = wacnPattern.Match(text);
                        Match acomMatch = msPattern.Match(text);
                        // Found wacn.date
                        if (wacnMatch.Success)
                        {
                            // extract date out
                            ds.WACNDate = wacnMatch.Groups[1].Value;
                        }

                        // Found ms.date
                        if (acomMatch.Success)
                        {
                            // extract date out
                            ds.ACOMDateWACN = acomMatch.Groups[1].Value;
                        }

                        ds.URL = file.Name;
                    }

                    result[file.Name] = ds;
                }
            }

            DirectoryInfo[] allDir = folder.GetDirectories();

            foreach (var directory in allDir)
            {
                if(ignore.directoryList.Contains(directory.Name))
                {
                    continue;
                }
                else
                {
                    GetFileListDateFrom815(directory, result, ignore);
                }
            }
        }
    }

    /// <summary>
    /// Store fields.
    /// </summary>
    public class DataStore
    {
        public string ACOMDate { get; set; }
        public string ACOMDateWACN { get; set; }
        public string WACNDate { get; set; }

        public string URL { get; set; }
    }

    /// <summary>
    /// Ignore object contains section name and its list.
    /// </summary>
    public class Ignore
    {
        public string section { get; set; }
        public ArrayList directoryList { get; set; }
        public ArrayList fileList { get; set; }
    }
}
