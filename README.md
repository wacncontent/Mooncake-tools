## Mooncake tools

This repo contains some tools that used in daily work, each folder contains detailed README.md.

> Note: run `dos2unix file-list.txt` to convert file format from windows to linux when command has to read file list.
> Since Windows and Linux has different ending character, it's necessary to to that.

1. ACOM-Report: ACOM monthly report generation tool.
2. KPI: ACN monthly KPI report tool. 

    > **Note**: this Tool has been abandoned. See the replacement at [this GitHub Repo](https://github.com/wacncontent/KPI_tool)
3. Lines-Changed: ACN git repo lines and files changed tool.
4. selenium: ACN webpage component.
5. DeleteState: Check ACN delete state in ACN repo.
6. MoonCake Scanner: Scan ACN/PPE for broken links
    
    > Current pool threads are 200, you could change it to different value to suit your PC.  
    > `pool = mp.Pool(200)`
6. Tools: bash script tools to help finish work above.



Thanks!
