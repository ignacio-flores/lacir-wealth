# Wealth Inequality in Latin America Research Reproducibility

## About the Study
"Wealth Inequality in Latin America" is a 2023 research paper by Rafael Carranza, Mauricio De Rosa, and Ignacio Flores. It explores wealth distribution in Latin America.

### Paper Details
- **Title**: Wealth Inequality in Latin America
- **Authors**: Rafael Carranza, Mauricio De Rosa, Ignacio Flores
- **Year**: 2023
- **Abstract**: The study examines wealth distribution in Latin America...
- **Full Paper**: [Link to LSE Research Online](http://eprints.lse.ac.uk/119426/)

## Repository Structure
### Folder Structure
- `code/Stata/`: Contains the Stata code files.
- `results/`: Stores output results.
- `figures/`: Contains generated figures and charts.

### Running the Code
1. For the full reproducible file, download from [ignacioflores.com/reproducibility/lacir-wealth.zip](https://www.ignacioflores.com/reproducibility/lacir-wealth.zip) and extract it.
2. Navigate to `code/Stata/`.
3. Set the working directory in line 6 of `run_everything.do`.
4. Before running the code, ensure the following Stata packages are installed:
   - `fastgini`
   - `ineqdecgini`
   - `egenmore`
   - `grstyle`
   - `palettes`
   - `colrspace`
   - `ineqdec0`
   - `grc1leg`
   You can install these packages using `ssc install [package_name]` in Stata.
5. Run `run_everything.do`.

## Data and Reproducibility
Datasets necessary for full reproducibility are available for download separately due to their size.

## Citation

- APA:
 Carranza, R., De Rosa, M., & Flores, I. (2023). Wealth inequality in Latin America. London School of Economics and Political Science, LSE Library.

- Bibtex:
```
@article{carranza2023wealth,
title={Wealth Inequality in Latin America},
author={Carranza, Rafael and De Rosa, Mauricio and Flores, Ignacio},
year={2023},
publisher={International Inequalities Institute, London School of Economics and Political Science}
}
```