## Common commands

### 1. Git

```bash
# Get all the added filename with date
git log --date=short --name-status --pretty=format:"%cd" --diff-filter=A --
# Get all the removed filename with date
git log --date=short --name-status --pretty=format:"%cd" --diff-filter=D --

# Get files log with author, date, message
git log --pretty=format:"%an %cd %h %s" --date=short --name-status
# Get line changes
git log --oneline --shortstat
```

### 2. Excel
```vb
-- Find if cell A2 is in Column A, TRUE: exists; FALSE: not exists.
NOT(ISNA(VLOOKUP(A2,A:A,1,FALSE)))

-- xxx.md -> www.azure.cn/documentation/articles/xxxx
HYPERLINK(CONCAT("www.azure.cn/documentation/articles/", SUBSTITUTE( "xxxx.md", ".md", "")))

-- substitue cell B1 conents with # and then trim extra blank character.
TRIM( SUBSTITUTE(B1, "#", ""))
```

### 3. VB Macro
```vb
' Example:
' ACOM_CATEGORY('articles/service/document.md') -> Article
' ACOM_CATEGORY('articles/service/document.md') -> service / others
' ACOM_CATEGORY('articles/service/document.md') -> document.md

' Function to extract CATEGORY, SERVICE and FILENAME
' from given string and delimiter.
' Author: Steven
' Date: 20160629

' Get acom file category
Function ACOM_CATEGORY(str, sep) As String
    Dim V() As String
    V = Split(str, sep)

    If StrComp(V(0), "articles", vbTextCompare) = 0 Then
        ACOM_CATEGORY = "Article"
    Else
        ACOM_CATEGORY = "Include"
    End If
End Function

' Get acom service, only available for articles
Function ACOM_SERVICE(str, sep) As String
    Dim V() As String
    
    V = Split(str, sep)
    If UBound(V) = 2 Then
        ACOM_SERVICE = V(1)
    Else
        ACOM_SERVICE = "Others"
    End If
End Function

' Get acom file name from path
Function ACOM_FILENAME(str, sep) As String
    Dim V() As String
    V = Split(str, sep)
    ACOM_FILENAME = V(UBound(V))
End Function
```