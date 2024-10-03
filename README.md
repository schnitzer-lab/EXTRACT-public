[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=schnitzer-lab/EXTRACT-public)  [![View EXTRACT-public on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/96083-extract-public)
# EXTRACT 

## Introduction

<img src="https://user-images.githubusercontent.com/56279691/206535976-80f4cc28-eb4f-4dd6-848a-fde4cd5fe20f.png" width="40%" align="right" alt="Example_movie">

EXTRACT is a  <ins>t</ins>ractable and <ins>r</ins>obust  <ins>a</ins>utomated <ins>c</ins>ell extraction  <ins>t</ins>ool for calcium imaging, which *extracts* the activities of cells as time series from both one-photon and two-photon Ca<sup>2+</sup> imaging movies. EXTRACT makes minimal assumptions about the data, which is the main reason behind its high robustness and superior performance. 




We show an example output of EXTRACT on a low SNR movie, in the figure on the right donated by Dr. [Peng Yuan](http://itbr.fudan.edu.cn/en/info/1366/2409.htm). Please note that this is the raw output, with no post-processing and/or manual annotation/selection by users. This run is a result of a batch processing of >30 sessions, optimized only once at the beginning of the study, with no extra parameter tweaking particular to this session. EXTRACT needs to be optimized per surgery/imaging modality type (practically once in the life-time of a study). For a trained person (feel free to schedule a tutorial for your lab!), this process usually takes around few minutes. 

## Installation

Use the [Add-on Explorer](https://www.mathworks.com/products/matlab/add-on-explorer.html) and search for EXTRACT (recommended), or install files from this GitHub repo.

## Getting Started

Browse the tutorial examples to quickly gain expertise with EXTRACT. You can view the tutorials :eyes: or run:arrow_forward: most of the tutorials on [MATLAB Online](https://www.mathworks.com/products/matlab-online.html). Or work any of the tutorials on your own computer.



| Tutorial | View | Run |
| -------- | ---- | --- |
| 1 - Starting Code | [![File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F6d2fb9fc-2974-4fac-9eb3-83340b9f5095%2Fae967b44-8a32-449b-ac35-7559e44fe5ba%2Ffiles%2FLearning%20materials%2FLecture%20Tutorials%2FTutorial%201%20-%20Starting%20code%2Ftutorial_1.mlx&embed=web) | [![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=schnitzer-lab/EXTRACT-public&file=Learning%20Materials/Lecture%20Tutorials/Tutorial%201%20-%20Starting%20code/tutorial_1.mlx) | 
| 2 - Parallelization | [![File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F6d2fb9fc-2974-4fac-9eb3-83340b9f5095%2Fae967b44-8a32-449b-ac35-7559e44fe5ba%2Ffiles%2FLearning%20materials%2FLecture%20Tutorials%2FTutorial%202%20-%20Parallelization%2Ftutorial_2.mlx&embed=web) | [![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=schnitzer-lab/EXTRACT-public&file=Lecture%20Tutorials/Tutorial%202%20-%20Cell%20refinement/tutorial_2.mlx) | 
| 3 - Preprocessing | [![File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F6d2fb9fc-2974-4fac-9eb3-83340b9f5095%2Fae967b44-8a32-449b-ac35-7559e44fe5ba%2Ffiles%2FLearning%20materials%2FLecture%20Tutorials%2FTutorial%203%20-%20Preprocessing%2Ftutorial_3.mlx&embed=web) | [![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=schnitzer-lab/EXTRACT-public&file=Lecture%20Tutorials/Tutorial%203%20-%20Preprocessing/tutorial_3.mlx) | 
| 4 - Cellfinding | [![File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F6d2fb9fc-2974-4fac-9eb3-83340b9f5095%2Fae967b44-8a32-449b-ac35-7559e44fe5ba%2Ffiles%2FLearning%20materials%2FLecture%20Tutorials%2FTutorial%204%20-%20Cellfinding%2Ftutorial_4.mlx&embed=web) | [![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=schnitzer-lab/EXTRACT-public&file=Lecture%20Tutorials/Tutorial%204%20-%20Cell%20finding/tutorial_4.mlx) | 
| 5 - Cell refinement | [![File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F6d2fb9fc-2974-4fac-9eb3-83340b9f5095%2Fae967b44-8a32-449b-ac35-7559e44fe5ba%2Ffiles%2FLearning%20materials%2FLecture%20Tutorials%2FTutorial%205%20-%20Cell%20refinement%2Ftutorial_5.mlx&embed=web) | [![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=schnitzer-lab/EXTRACT-public&file=Lecture%20Tutorials/Tutorial%205%20-%20Cell%20refinement/tutorial_5.mlx) | 
| 6 - Final robust regression | [![File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://viewer.mathworks.com/?viewer=live_code&url=https%3A%2F%2Fwww.mathworks.com%2Fmatlabcentral%2Fmlc-downloads%2Fdownloads%2F6d2fb9fc-2974-4fac-9eb3-83340b9f5095%2Fae967b44-8a32-449b-ac35-7559e44fe5ba%2Ffiles%2FLearning%20materials%2FLecture%20Tutorials%2FTutorial%206%20-%20Final%20robust%20regression%2Ftutorial_6.mlx&embed=web) | [![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=schnitzer-lab/EXTRACT-public&file=Lecture%20Tutorials/Tutorial%206%20-%20Final%20robust%20regression/tutorial_6.mlx) | 

### The user manual

Please see the user manual inside the "Learning materials" folder. The user manual has a quick start guide, accompanied with several tutorials. The user manual also has several key insights for increasing the quality of cell extraction.

### Instructional video

You can watch our 10-minute video about EXTRACT: <a href="https://www.youtube.com/watch?v=qmCSJWcClNo" target="_blank"><img src="https://github.com/user-attachments/assets/7dca6215-e99d-4f49-aaa5-250f08dc967b" width="40%" align="right" alt="Instructional video"></a>

<!---
this seems not to work on GitHub but it does work in standard Markdown readers
<video src="https://wds-matlab-community-toolboxes.s3.amazonaws.com/EXTRACT/EXTRACT_overview.mp4" width="640" height="480" controls></video>
-->


<!---
This is a GitHub link to the whole video, which is the only way to get them to show in GitHub READMEs. GitHub seems to hide traditional video players.
https://github.com/user-attachments/assets/af43ebfb-81ee-4a56-af19-74e28e496aca
-->


### Schedule a tutorial session!

Thank you for your interest in EXTRACT, a cell extraction routine with native GPU implementation.  To receive occasional updates about new releases, to ask questions about EXTRACT usage, or schedule a tutorial session for your lab, please send an email to extractneurons@gmail.com along with your name and institution. (Please be sure to add this email to your contact list so that replies and announcements do not go to your spam folder).  Thank you!  

### Questions

EXTRACT code is primarily written by Dr. Hakan Inan and Fatih Dinc in collaboration with many researchers in Schnitzerlab. The database is maintained by the current members of Schnitzerlab. If you have any questions or comments, please open an issue or contact via email `extractneurons@gmail.com`.

## Citations

EXTRACT is described in two accompanying papers: [Dinc & Inan et al., 2024](https://www.biorxiv.org/content/10.1101/2021.03.24.436279v3.full.pdf) and [Inan et al., 2017](https://papers.nips.cc/paper/2017/file/e449b9317dad920c0dd5ad0a2a2d5e49-Paper.pdf). Please cite these papers if you use EXTRACT in your own work.


