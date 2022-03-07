# ConceptWAS -  a high-throughput approach for detecting COVID-19 symptoms from EHR notes


The source code for published paper: 
1. Zhao J, Grabowska ME, Kerchberger VE, Smith JC, Eken HN, Feng Q, et al. ConceptWAS: A high-throughput method for early identification of COVID-19 presenting symptoms and characteristics from clinical notes. Journal of Biomedical Informatics. 2021;117:103748. [doi: 10.1016/j.jbi.2021.103748] (https://pubmed.ncbi.nlm.nih.gov/33774203/)

**Abstract**

Objective
Identifying symptoms and characteristics highly specific to coronavirus disease 2019 (COVID-19) would improve the clinical and public health response to this pandemic challenge. Here, we describe a high-throughput approach – Concept-Wide Association Study (ConceptWAS) – that systematically scans a disease's clinical manifestations from clinical notes. We used this method to identify symptoms specific to COVID-19 early in the course of the pandemic.

Methods
We created a natural language processing pipeline to extract concepts from clinical notes in a local ER corresponding to the PCR testing date for patients who had a COVID-19 test and evaluated these concepts as predictors for developing COVID-19. We identified predictors from Firth's logistic regression adjusted by age, gender, and race. We also performed ConceptWAS using cumulative data every two weeks to identify the timeline for recognition of early COVID-19-specific symptoms.

Results
We processed 87,753 notes from 19,692 patients subjected to COVID-19 PCR testing between March 8, 2020, and May 27, 2020 (1,483 COVID-19-positive). We found 68 concepts significantly associated with a positive COVID-19 test. We identified symptoms associated with increasing risk of COVID-19, including “anosmia” (odds ratio [OR] = 4.97, 95% confidence interval [CI] = 3.21–7.50), “fever” (OR = 1.43, 95% CI = 1.28–1.59), “cough with fever” (OR = 2.29, 95% CI = 1.75–2.96), and “ageusia” (OR = 5.18, 95% CI = 3.02–8.58). Using ConceptWAS, we were able to detect loss of smell and loss of taste three weeks prior to their inclusion as symptoms of the disease by the Centers for Disease Control and Prevention (CDC).

Conclusion
ConceptWAS, a high-throughput approach for exploring specific symptoms and characteristics of a disease like COVID-19, offers a promise for enabling EHR-powered early disease manifestations identification.








