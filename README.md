# Project4
Study investigating the effect of errors on subsequent correct trials

Study 4 Directory

L:/Study_4

Individual data

All individuals are saved in folders based on their subject number (e.g. L:/Study_4/802).

These folders contain the following sub folders:

•	1st_level – this contains beta values for the first level analysis in MNI space.

Some participants have legacy subfolders which can be ignored:

1.	Individual – this was the analysis in native space with two subfolders:

I.	Analysis – this contains a copy of the combined data, that was analysed directly. A copy was made to ensure the data used at the 2nd level was not tampered with.

II.	Combined – This contains the beta images from the primary combined analysis (so called because we combined cue and feedback events into the same design matrix).

2.	MNI – this was the analysis in MNI space, with just one subfolder:

I.	Combined – This contains the beta images from the primary combined analysis (so called because we combined cue and feedback events into the same design matrix).

NB. The up-to-date 1st level was not run on all participants, only those for whom the analysis progressed further, and for these legacy subfolders were moved to an ‘old’ folder.

•	anat – the anatomical images (prefix sF7T), segmented native images (prefix c) and segmented dartel images (prefix rc). Also creation of the shoot normalisation template saved 3 files prefixed with j_rc, v_rc and y_rc. In participant 802 only the shoot templates were saved.

•	DICOM – the original DICOM images.

•	epi – the functional images, originals (prefix fF7T), unwarped (prefix ufF7T), smoothed in native space (prefix sufF7T) and smoothed/normalised using shoot (prefix swufF7T). Where the prefix includes ‘ALT’ this was the images normalised using standard SPM protocols.

•	fmap – field map images with two subfolders:

1.	phase – prefix sF7T.

2.	magnitude – two images prefixed sF7T.

•	quality_control – contains all outputs from quality control scripts. Includes files titled ‘file_all’ and ‘file_all2’ (which are the inputs for the ‘study_log’ results excel file, ‘file_all2’ looking at data with breaks removed). Also ‘hm’ which is head motion, and ‘output’.

•	scripts – contains the SPM scripts for importing the DICOM images, and for calculating VDM/unwarping/realigning the data, coregistration, smoothing, and segmenting for this specific participant.

Finally there is a design2.mat file which contains all the trial data for each participant. This has been reworked in multiple ways, but critically follows the same structure re columns:

1.	Trial number.

2.	Experimental condition 1= X, 2 = C.

3.	Rule (1-10).

4.	The target (1-3) that would be correct.

5.	The target (1-3) which was selected.

6.	Whether the participant was right (2) or wrong (1) or missed the target (0).

7.	Reaction time (time between target onset and onset of triggering fixation).

8.	Cue onset (sec).

9.	Cue offset.

10.	Cue duration.

11.	Target onset.

12.	Target offset.

13.	Target duration.

14.	Feedback onset.

15.	Feedback offset.

16.	Feedback duration.


Second Level Data

This is saved under ‘2nd_level’, within which there are two subfolders:

•	Cuefeed – this contains beta images for the cue and feedback analysis. There are two subfolders:

1.	aROI – contains cerebellar and frontal lobe masks.

2.	output – contains output data for analyses at specific coordinates for different tests, plus the plots used in the paper .

•	Target – this contains beta images for the target focused analysis, and also has an output folder like above.



Appendices

Some of the appendix images are saved here.



Baseline

Saved under ‘baseline’ is the beta image for establishing baseline brain activity at each voxel.



Images

In here are some of the images used in the paper.



Quality_control

This saves the correlation data across participants, and the images used for checking head motion and epi data.



ROI

Has a backup of all possible masks used. ‘mask_smooth.nii’ is the frontal lobe mask and ‘ROI_whole_cerebellum_MNI’ is the cerebellar mask.



Scripts

•	Create_run_v4 – this was used to generate the timings, using the data_10shape_1760TR folder to house outputs.

•	Generate_control_v2 – this was also used for generating the study data, creating a random set of control allocations.

•	Script_check_data_v6 – this was used once data was collected, to create outputs like ‘design2.mat’ and to check aspects of the data.

•	Step_1_importDICOM – imported DICOM images and converted to nifty.

•	Step_2_calculate_VDM_v3 – created VDM, unwarped, realigned, coregistered, smoothed and segmented the data.

•	Step_3_1st_level_comb – this ran the first level analysis in native space.

•	Step_4_QA_scriptv3 – ran the quality assurance outputted in the QA folder above.

•	Step_5_shoot_template – generates a shoot template from all subjects with an anatomical image.

•	Step_6_shoot_normalisev2 – applies this template to normalise the epi images.

•	Step_7_normalise – uses standard SPM normalisation to normalise epi images with the ALT prefix.

•	Step_8_1st_level_MNI_comb – runs the 1st level analysis on the MNI normalised data (using the step_3 job script).

•	Step_9_QA_correlation_check_combined – runs further checks of correlations, modified from step_4 due to a change in design matrix.

•	Step_10_2nd_level_comb – the 2nd level analysis of the cues and feedback.

•	Step_10_2nd_level_target – the 2nd level analysis of target events.

•	Step_11_baseline_comb_job – the 2nd level analysis which produced a beta value corresponding to the mean baseline value at each voxel across the group.

•	Step_12_voxel_check – there are four versions, one for each type of analysis (cue/feed and target) and for both 1st and 2nd level analyses. This was used to check for significance and plot the BOLD responses at a specified coordinate.

•	Step_13_1st_level_contrasts – this runs a set of prespecified contrasts across all participants included in the fixed effects analysis at the first level. Quicker than typing them in manually.

•	Step_14_save_plots_2nd_level – saves a single plot of all effects in the cue/feed analysis altered to be suitable for papers (larger text and less detail).

•	Step_15_save_plots_2nd_level_eventXcondition – saves two plots (splitting by cue and feedback) altered to be suitable for papers.



Scripts

This contains ‘Version8_10Rules’ which is the study itself run using Experiment Builder and ‘Version8_10Rules_deploy2’ which is the deployed version. There is also Version7 of the same, which was used for participant 802. The deployed version8 folder contains a ‘results’ subfolder with all participant’s data (e.g. p803). The key files are:

•	Data_803.s2rx/smrx – this is the spike file

•	P803.edf – this is the dataviewer file



Other Files

There is an excel file titled ‘study_log’ which contains figures and participant data. There are 3 tabs:

•	Screening_Data – information about all subjects who applied

•	Testing_Data – information about all subjects who were tested (removed participants at the bottom)

•	Summary_Data – information about what was collected for each subject, and some key details

Finally there is an excel file titled ‘Pilot_log’ which unsurprisingly has piloting data contained within.


