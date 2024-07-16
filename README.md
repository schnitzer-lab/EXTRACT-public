[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=schnitzer-lab/EXTRACT-public)  [![View EXTRACT-public on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/96083-extract-public)
# EXTRACT 

## Introduction

<img src="https://user-images.githubusercontent.com/56279691/206535976-80f4cc28-eb4f-4dd6-848a-fde4cd5fe20f.png" width="40%" align="right" alt="Example_movie">

EXTRACT is a  <ins>t</ins>ractable and <ins>r</ins>obust  <ins>a</ins>utomated <ins>c</ins>ell extraction  <ins>t</ins>ool for calcium imaging, which *extracts* the activities of cells as time series from both one-photon and two-photon Ca<sup>2+</sup> imaging movies. EXTRACT makes minimal assumptions about the data, which is the main reason behind its high robustness and superior performance. 




We show an example output of EXTRACT on a low SNR movie, in the figure on the right donated by Dr. [Peng Yuan](http://itbr.fudan.edu.cn/en/info/1366/2409.htm). Please note that this is the raw output, with no post-processing and/or manual annotation/selection by users. This run is a result of a batch processing of >30 sessions, optimized only once at the beginning of the study, with no extra parameter tweaking particular to this session. EXTRACT needs to be optimized per surgery/imaging modality type (practically once in the life-time of a study). For a trained person (feel free to schedule a tutorial for your lab!), this process usually takes around few minutes. 

You can watch our instructional video:
<video src="https://wds-matlab-community-toolboxes.s3.amazonaws.com/EXTRACT/EXTRACT_overview.mp4" width="640" height="480" controls></video>

https://github.com/user-attachments/assets/af43ebfb-81ee-4a56-af19-74e28e496aca



## Installation

It is fairly straightforward to install EXTRACT. Simply download all the files from the repository and include them in the MATLAB path. Installation is complete. 

Please note that EXTRACT makes use of various packages and toolboxes:

- Bioinformatics Toolbox
- Econometrics Toolbox
- Image Processing Toolbox
- Parallel Computing Toolbox 
- Signal Processing Toolbox 
- Statistics and Machine Learning Toolbox
- Wavelet Toolbox

## Getting Started

Browse the tutorial examples to quickly gain expertise with EXTRACT. You can view the tutorials :eyes: or run:arrow_forward: most of the tutorials on [MATLAB Online](https://www.mathworks.com/products/matlab-online.html). Or work any of the tutorials on your own computer.

| Tutorial | View | Run |
| -------- | ---- | --- |
| 1 - Starting Code | [:eyes:]() | [:arrow_forward:](https://matlab.mathworks.com/open/github/v1?repo=schnitzer-lab/EXTRACT-public&file=Learning%20materials/Lecture%20Tutorials/Tutorial%201%20-%20Starting%20code/tutorial_1.mlx) | 
| 2 - Parallelization | [:eyes:]() | [:arrow_forward:](https://matlab.mathworks.com/open/github/v1?repo=schnitzer-lab/EXTRACT-public&file=Learning%20materials/Lecture%20Tutorials/Tutorial%202%20-%20Parallelization/tutorial_2.mlx) | 
| 3 - Preprocessing | [:eyes:]() | [:arrow_forward:](https://matlab.mathworks.com/open/github/v1?repo=schnitzer-lab/EXTRACT-public&file=Learning%20materials/Lecture%20Tutorials/Tutorial%203%20-%20Preprocessing/tutorial_3.mlx) | 
| 4 - Cellfinding | [:eyes:]() | (*) | 
| 5 - Cell refinement | [:eyes:]() | (*) | 
| 6 - Final robust regression | [:eyes:]() | [:arrow_forward:](https://matlab.mathworks.com/open/github/v1?repo=schnitzer-lab/EXTRACT-public&file=Learning%20materials/Lecture%20Tutorials/Tutorial%206%20-%20Final%20robust%20regression/tutorial_6.mlx) | 

(*) Tutorials 4 and 5 will download a 2.93 GB file that is too large for free Matlab Online.

### The user manual

Please see the user manual inside the "Learning materials" folder. The user manual has a quick start guide, accompanied with several tutorials. The user manual also has several key insights for increasing the quality of cell extraction.

### Schedule a tutorial session!

Thank you for your interest in EXTRACT, a cell extraction routine with native GPU implementation.  To receive occasional updates about new releases, to ask questions about EXTRACT usage, or schedule a tutorial session for your lab, please send an email to extractneurons@gmail.com along with your name and institution. (Please be sure to add this email to your contact list so that replies and announcements do not go to your spam folder).  Thank you!  

### Questions

EXTRACT code is primarily written by Dr. Hakan Inan and Fatih Dinc in collaboration with many researchers in Schnitzerlab. The database is maintained by the current members of Schnitzerlab. If you have any questions or comments, please open an issue or contact via email `extractneurons@gmail.com`.

## Citation

If you use EXTRACT for your own research, please cite the following works: 

```
@article{inan2021fast,
	author = {Inan, Hakan and Schmuckermair, Claudia and Tasci, Tugce and Ahanonu, 
	Biafra and Hernandez, Oscar and Lecoq, Jerome and Dinc, Fatih and Wagner, 
	Mark J and Erdogdu, Murat and Schnitzer, Mark J},
	title = {Fast and statistically robust cell extraction from 
	large-scale neural calcium imaging datasets},
	elocation-id = {2021.03.24.436279},
	year = {2021},
	doi = {10.1101/2021.03.24.436279},
	URL = {https://www.biorxiv.org/content/early/2021/03/25/2021.03.24.436279},
	eprint = {https://www.biorxiv.org/content/early/2021/03/25/2021.03.24.436279.full.pdf},
	journal = {bioRxiv}
}
```


```Latex
@article{inan2017robust,
  title={Robust estimation of neural signals in calcium imaging},
  author={Inan, Hakan and Erdogdu, Murat A and Schnitzer, Mark},
  journal={Advances in neural information processing systems},
  volume={30},
  pages={2901--2910},
  year={2017}
}
```

Links to accompanying papers: [Inan et al., 2021](https://www.biorxiv.org/content/10.1101/2021.03.24.436279v1.full.pdf) and [Inan et al., 2017](https://papers.nips.cc/paper/2017/file/e449b9317dad920c0dd5ad0a2a2d5e49-Paper.pdf).

## License

Copyright (C) 2020 Schnitzerlab

Licensed under the MIT license:      

http://www.opensource.org/licenses/mit-license.php  

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:  

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.  

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.









