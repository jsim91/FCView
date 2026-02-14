# FCView

Interactive Shiny application for exploring [FCSimple](https://github.com/jsim91/FCSimple) flow cytometry analysis results.

## Installation

Install FCView directly from GitHub using devtools:

```r
# Install devtools if not already installed
if (!require("devtools")) install.packages("devtools")

# Install FCView
devtools::install_github("jsim91/FCView")
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

See [FEATURES.md](FEATURES.md) for a full list of app features (general and comprehensive).
For compatibility, the cluster element should be renamed to "cluster" and the heatmap element renamed to "cluster_heatmap", no matter what algorithm was used during the calculation phase. The heatmap plot object can be dropped to shrink file size. Only the underlying heatmap matrix data is required. See layout below for more on this.

**Recommended Object Layout**

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

The easiest way to prepare your FCSimple analysis object for FCView is to use the `fcs_prepare_fcview_object()` function:

```r
# Prepare object with downsampling and save to file
prepared_obj <- FCSimple::fcs_prepare_fcview_object(
  my_analysis_object,
  downsample_size = 100000,
  clustering_algorithm = "leiden",
  output_dir = "output/fcview",
  file_name = "my_analysis_fcview"
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
