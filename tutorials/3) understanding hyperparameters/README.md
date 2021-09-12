# Hyperparameter Optimization with EXTRACT

This tutorial is about optimizing hyperparameters with EXTRACT. For the purpose of this tutorial, download the movie, whose link is given below. This is among those movies that we used for the Fig. 4 of our paper that introduces EXTRACT. Use the script 'tutorial_fig4.m' as a starting point to tune hyperparameters for most satisfactory cell extraction process. Follow the procedure outlined below. This should give you an intuitive understanding of how to maximize hyperparameters.

The movie: https://drive.google.com/file/d/1FGkpTDXgspXddR1GDpgm1ludbIQHFwlS/view?usp=sharing


## Understanding the main modules before diving into hyperparameters

The first step is to understand the general categories, that hyperparameters fall into and that an outside user needs to be able to navigate. While there are quite a few, most of them are self explanatory (like skip_dff that skips taking delta f over f of the movie). On the other hand, the best way to understand the parameters is to divide them into corresponding modules. EXTRACT has 3 main modules: 

- Preprocessing: At the minimum, the movie is preprocessed such that the baseline activity of cells correspond to zero, as is consistent with the assumptions of cell extrraction. There are other (optional) procedures happening inside the preprocess module as well, whose aim is to increase the SNR of the movie. We will discuss these below.

- Cell finding: Once the movie is preprocessed and is ready for cell extraction, EXTRACT first identifies the regions of interest in a one-by-one fashion. This step is called cell finding. EXTRACT employs an additional smoothing procedure inside the cell finding module to increase the efficiency of cell finding but these procedures do not carry out to cell refinement to prevent cross-contamination in the final traces. Hyperparameters that belong to this module usually have 'cellfind' in front of them, meaning that they ONLY affect the cell finding process.

- Cell refinement: Once all the cells are found in the cell finding module, EXTRACT performs what we call as the "cell-refinement." The main purpose is to delete the spurious and/or duplicate cells while accurately estimating the traces by taking into account all the cells found. Inside the cell refinement module, EXTRACT computes some quality parameters and discards cell candidates that fail to score sufficiently on those parameters. The thresholds on these quality metrics are determined by the outside user via the 'thresholds.' Thus, the most important hyperparameters associated with the cell refinement module are inside 'config.thresholds.' Keeping the thresholds too tight will lead to some actual cells being discarded, but keeping them too lose will return too much false-positives and inaccurate trace estimation. 

While there are no particular hyperparameters associated with them, EXTRACT has two more modules. We will discuss them on another tutorial. For now, it is important to emphasize that running EXTRACT is first understanding these three modules. Other two are optional and can be skipped, although we strongly advise against skipping them!

Finally, all the hyperparameters of EXTRACT controlled by an outside user is given inside the function 'get_defaults.m', which is the only script in the homepage of the repository. One can and should always double check the exact spelling of the hyperparameters by checking this script. We advise that users do not change this script, the defaults are picked to be most approprioate for a general set of movies. This script will never overwrite user given configurations.

## General control hyperparameters



