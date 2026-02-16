# FCView

Interactive Shiny application for exploring [FCSimple](https://github.com/jsim91/FCSimple) flow cytometry analysis results.

## Installation

Install FCView using BiocManager to ensure all dependencies (including Bioconductor packages) are properly installed:

```r
# Install BiocManager if not already installed
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

# Install FCView with all dependencies
BiocManager::install("jsim91/FCView")
```

## Usage

Launch the FCView app:

```r
library(FCView)
run_fcview()
```

## Data Requirements

The input object, saved in .RData format, should contain the following elements, as formatted by FCSimple functions unless otherwise noted:
  - data `[required]`
  - source `[required]`
  - run_date `[required]`
  - metadata `[required]`
  - umap `[recommended]`
  - tsne `[recommended]`
  - cluster `[required]`
  - cluster_heatmap `[required]`

See [FEATURES.md](FEATURES.md) for a full list of app features (general and comprehensive). See layout below for more on input formatting. ```FCSimple::fcs_prepare_fcview_object``` should do the heavy lifting as long as the following functions have been run on your analysis object:
  - ```FCSimple::fcs_join```
  - ```FCSimple::fcs_reduce_dimensions```
  - ```FCSimple::fcs_cluster```
  - ```FCSimple::fcs_cluster_heatmap```
  - ```FCSimple::fcs_calculate_abundance``` with report_as = 'frequency'
  - ```FCSimple::fcs_calculate_abundance``` with report_as = 'count'

Additionally:
  - ```FCSimple::fcs_add_metadata``` can be used to add additional metadata, such as clinical endpoints, time points, demographic features, etc that are associated with your samples.

**Object Layout**

Top-level structure

| Element | Type | Description |
| --- | --- | --- |
| `data` | numeric matrix | Feature measurements matrix |
| `source` | character | Sample source identifiers |
| `run_date` | character | Run timestamps |
| `metadata` | data.frame | Sample source level metadata |
| `umap` | list | UMAP coordinates + settings (see below) |
| `tsne` | list | tSNE coordinates + settings (see below) |
| `cluster` | list | Clustering result (see below) |
| `cluster_heatmap` | list | Cluster heatmap result (see below) |

`umap` sub-structure

| Element | Type | Description | Function |
| --- | --- | --- | --- |
| `coordinates` | data.frame | Embedding coordinates | FCSimple::fcs_reduce_dimensions |
| `settings` | list | UMAP parameters | FCSimple::fcs_reduce_dimensions |

`tsne` sub-structure

| Element | Type | Description | Function |
| --- | --- | --- | --- |
| `coordinates` | data.frame | Embedding coordinates | FCSimple::fcs_reduce_dimensions |
| `settings` | list | tSNE parameters | FCSimple::fcs_reduce_dimensions |

`cluster` sub-structure

| Element | Type | Description | Function |
| --- | --- | --- | --- |
| `clusters` | factor | Cluster membership | FCSimple::fcs_cluster |
| `settings` | list | Clustering parameters | FCSimple::fcs_cluster |
| `abundance` | numeric matrix | Sample cluster frequency array | FCSimple::fcs_calculate_abundance |
| `counts` | numeric matrix | Sample cluster counts array | FCSimple::fcs_calculate_abundance |

`cluster_heatmap` sub-structure

| Element | Type | Description | Function |
| --- | --- | --- | --- |
| `heatmap_tile_data` | numeric matrix | Heatmap data | FCSimple::fcs_cluster_heatmap |

## Preparing Data for FCView

Again, the easiest way to prepare your FCSimple analysis object for FCView is to use the `fcs_prepare_fcview_object()` function:

```r
# Prepare object with downsampling and save to file
prepared_obj <- FCSimple::fcs_prepare_fcview_object(
  my_analysis_object,
  downsample_size = 100000,
  clustering_algorithm = "leiden",
  output_dir = "output/fcview",
  file_name = "my_analysis_fcview" # note: do not include a file extension; it is added internally
)
```

This function will:
- Remove non-essential fields to reduce file size
- Standardize clustering algorithm names to 'cluster' for compatibility
- Optionally downsample cells while maintaining consistency across all fields
- Save the prepared object as an .RData file ready for upload

See `?FCSimple::fcs_prepare_fcview_object` for more details.

## Features

See [FEATURES.md](FEATURES.md) for a full list of app features.

## License

MIT License - see [LICENSE](LICENSE) file for details.
