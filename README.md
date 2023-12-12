# Wealth Inequality in Latin America Research Reproducibility

## About the Study
"Wealth Inequality in Latin America" is a 2023 research paper by Rafael Carranza, Mauricio De Rosa, and Ignacio Flores. It explores wealth distribution in Latin America.

### Paper Details
- **Title**: Wealth Inequality in Latin America
- **Authors**: Rafael Carranza, Mauricio De Rosa, Ignacio Flores
- **Year**: 2023
- **Abstract**:  How wealth has accumulated in the region and how is it distributed across households? Despite being widely recognized for its extreme income inequality, reliable data on wealth is scarce, partial and oftentimes contradictory, making it difficult to answer
these basic questions. In this study, we estimate aggregates based on macroeconomic
data, and inequality based on recently available surveys. We contrast our results
with the literature, with a handful of state-of-the-art estimates from administrative
sources, and with more available but extrapolated estimates from Credit Suisse and
wid.world. Considering all the evidence, we distinguish reliable facts from what can
only be conjectured or speculated. We find that aggregate wealth increased over two
decades in four countries, now ranging close to 3.5 the national income for market
value estimates and 5-6 times at book values. We also find that wealth inequality is
amongst the highest in the world were it can be measured. Given data limitations,
one can only speculate about aggregates in opaque countries and about inequality
trends in any country in the region. Although recent research in the developed world
has focused in combining data sources to better understand wealth, the region lags
behind and urgently requires more and better public information
- **Full Paper**: [Link to LSE Research Online](http://eprints.lse.ac.uk/119426/)

## Repository Structure
### Folder Structure
- `code/Stata/`: Contains the Stata code files.
- `results/`: Stores output results.
- `figures/`: Contains generated figures and charts.

### Running the Code
1. For the full reproducible file, download `lacir-wealth.zip` from [ignacioflores.com/reproducibility/](http://www.ignacioflores.com/reproducibility/) and extract it.
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
