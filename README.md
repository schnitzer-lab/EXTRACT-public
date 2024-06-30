[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/github/v1?repo=schnitzer-lab/EXTRACT-public)  [![View EXTRACT-public on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/96083-extract-public)
# EXTRACT 

## Schedule a tutorial session!

Thank you for your interest in EXTRACT, a cell extraction routine with native GPU implementation.  To receive occasional updates about new releases, to ask questions about EXTRACT usage, or schedule a tutorial session for your lab, please send an email to extractneurons@gmail.com along with your name and institution. (Please be sure to add this email to your contact list so that replies and announcements do not go to your spam folder).  Thank you!  

The EXTRACT team

## Introduction

EXTRACT is a  <ins>t</ins>ractable and <ins>r</ins>obust  <ins>a</ins>utomated <ins>c</ins>ell extraction  <ins>t</ins>ool for calcium imaging, which *extracts* the activities of cells as time series from both one-photon and two-photon Ca<sup>2+</sup> imaging movies. EXTRACT makes minimal assumptions about the data, which is the main reason behind its high robustness and superior performance. 

<img src="https://user-images.githubusercontent.com/56279691/206535976-80f4cc28-eb4f-4dd6-848a-fde4cd5fe20f.png" width="50%" align="right" alt="Example_movie">

<img src="https://user-images.githubusercontent.com/56279691/103445994-9e9a2780-4c8b-11eb-9693-6684cca73743.png" width="50%" align="right" alt="EXTRACT_pipeline">

We show an example output of EXTRACT on a low SNR movie, in the figure on the right donated by Dr. [Peng Yuan](http://itbr.fudan.edu.cn/en/info/1366/2409.htm). Please note that this is the raw output, with no post-processing and/or manual annotation/selection by users. This run is a result of a batch processing of >30 sessions, optimized only once at the beginning of the study, with no extra parameter tweaking particular to this session. EXTRACT needs to be optimized per surgery/imaging modality type (practically once in the life-time of a study). For a trained person (feel free to schedule a tutorial for your lab!), this process usually takes around few minutes. 

EXTRACT can be thought of as being part of a signal extraction pipeline, as illustrated by the figure on the right. The pipeline takes a raw 1p/2p Ca<sup>2+</sup> imaging movie as an input. Then, one performs motion correction and various pre-processing steps. Later, the processed movie is used by the EXTRACT algorithm to perform tractable and robust cell extraction, which puts out the temporal traces and spatial maps for future data analysis. EXTRACT code in this repository provides most of the pipeline (colored as green in the figure). We also provide some links to the external repositories whenever needed (colored as orange in the figure right).

Its main features and the mathematical foundations behind EXTRACT as well as a comparison with state-of-the-art methods can be found in the papers cited below (Links to papers: [Inan et al., 2021](https://www.biorxiv.org/content/10.1101/2021.03.24.436279v1.full.pdf) and [Inan et al., 2017](https://papers.nips.cc/paper/2017/file/e449b9317dad920c0dd5ad0a2a2d5e49-Paper.pdf)). If you use EXTRACT for your own research, please cite both of these works. 


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

## Installation

It is fairly straightforward to install EXTRACT. Simply download all the files from the repository and include them in the MATLAB path. Installation is complete. EXTRACT makes use of various packages and toolboxes, check out the [Dependencies](#dependencies) section. An example case of running EXTRACT after installation is provided in [Example movie extraction](#example-movie-extraction).


## Dependencies

EXTRACT requires, at least, the following toolboxes. With future releases, there may be need for further toolboxes.


- Bioinformatics Toolbox
- Econometrics Toolbox
- Image Processing Toolbox
- Parallel Computing Toolbox 
- Signal Processing Toolbox 
- Statistics and Machine Learning Toolbox
- Wavelet Toolbox


## Questions and comments

EXTRACT code is primarily written by Dr. Hakan Inan and Fatih Dinc in collaboration with many researchers in Schnitzerlab. The database is maintained by the current members of Schnitzerlab. If you have any questions or comments, please open an issue or contact via email `extractneurons@gmail.com`.


## License

Copyright (C) 2020 Schnitzerlab

Licensed under the MIT license:      

http://www.opensource.org/licenses/mit-license.php  

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:  

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.  

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.









