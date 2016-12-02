# Script to find automate scan links
# Date: 11/15/2016
# Author: Steven

# Constants
$TechFolder = "C:\Users\v-welian\Documents\GitHub\815"
$ScannerFolder = "C:\Users\v-welian\Documents\Visual Studio 2015\Projects\MoonCakeScanner\MoonCakeScanner"

# function to get file list and convert to url list under articles folder
function GetFiles($path = $pwd, [string[]]$exclude) 
{ 
    foreach ($item in Get-ChildItem $path)
    {
        if ($exclude | Where {$item -like $_}) { continue }

        if (Test-Path $item.FullName -PathType Container) 
        {
            # $item.Name 
            GetFiles $item.FullName $exclude
        } 
        elseif ($item.extension -eq ".md" ) {
            $item.Name | %{$_ -replace ".md", ""} | %{"https://www.azure.cn/documentation/articles/" + $_}
        }
        else {
            continue
        }
    } 
}

# Go to techcontent folder
cd $TechFolder

# Update our repo
git pull


# Get list
cd "articles"

GetFiles $PWD ('media') | Out-File -Encoding default site.txt

# convert dos to unix
dos2unix site.txt
echo "Generating url list.... OK"

# Running our python scanner
Move-Item site.txt $ScannerFolder -Force
cd $ScannerFolder

echo "Start running scanner"
# TODO
python main.py

echo "Finish scanning"

# Start to email to team members
$Outlook = New-Object -ComObject Outlook.Application
$Mail = $Outlook.CreateItem(0)
# $Mail.To = "v-welian@microsoft.com;v-johch@microsoft.com;v-junlch@microsoft.com;v-yiso@microsoft.com;v-dazen@microsoft.com"
$Mail.To = "v-welian@microsoft.com"
$Today = Get-Date -Format "yyyy-MM-dd"
$Mail.Subject = "ACN Broken Link - " + $Today
$Mail.Body ="Hi guys,`r`n`r`nAttached is the ACN broken link.`r`n`r`nRegards,`r`nSteven"
$file = $ScannerFolder + "\bad.md"
$Mail.Attachments.Add($file)
$Mail.Send()

echo "Done"