# Ext Chart

The goal of this project is to facilitate the drawing and manipulation of spectral sequences, by tracking the differential and multiplicative structures across pages of a given spectral sequence.

Ext Chart is open source software released under the [University of Illinois/NCSA Open Source License](http://opensource.org/licenses/NCSA).

Discussion on Freenode at #Ext-Chart.

# Development

Use Xcode to download the Ext Chart repository from GitHub:

1. Open Xcode and choose the Source Control > Check Out… menu item
2. Type **https://github.com/ecpeterson/Ext-Chart.git** in the repository location field and click Next
3. Select a folder in your disk where the project repository will be stored and click Check Out.

    Xcode will download the repository. Since we use third-party projects, Xcode will also ask you to check out each third-party project as an additional working copy. Choose Check Out… and click Next so that Xcode downloads all dependent projects.

4. We need to use a shared build folder for all projects in the workspace. Since this is an individual setting, you need to configure it in your system. In Xcode, choose the File > Workspace Settings… menu item. Click Advanced…, choose Shared Folder and type a folder name—we suggest ExtChartBuild.

When restarting Xcode, make sure you open Ext Chart’s workspace instead of its project.

