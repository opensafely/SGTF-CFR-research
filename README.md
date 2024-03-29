# S-gene target failure (SGTF) and case fatality risk (CFR)

This is a study of the CFR of the SARS-CoV-2 variant of concern B.1.1.7 (VOC) compared to the non-VOC. SGTF is used as a proxy for identifying the VOC.

This is the code and configuration for our analysis

* The original paper is published in Eurosurveillance https://www.eurosurveillance.org/content/10.2807/1560-7917.ES.2021.26.11.2100256
* The follow-up paper is published in Clinical Infectious Diseases https://doi.org/10.1093/cid/ciab754
* Raw model outputs, including charts, crosstabs, etc, are in `released_outputs/`
* If you are interested in how we defined our variables, take a look at the [study definition](analysis/study_definition.py); this is written in `python`, but non-programmers should be able to understand what is going on there
* If you are interested in how we defined our code lists, look in the [codelists folder](./codelists/).
* Developers and epidemiologists interested in the code should review
[DEVELOPERS.md](./docs/DEVELOPERS.md).

# About the OpenSAFELY framework

The OpenSAFELY framework is a new secure analytics platform for
electronic health records research in the NHS.

Instead of requesting access for slices of patient data and
transporting them elsewhere for analysis, the framework supports
developing analytics against dummy data, and then running against the
real data *within the same infrastructure that the data is stored*.
Read more at [OpenSAFELY.org](https://opensafely.org).

The framework is under fast, active development to support rapid
analytics relating to COVID19; we're currently seeking funding to make
it easier for outside collaborators to work with our system.  You can
read our current roadmap [here](ROADMAP.md).
