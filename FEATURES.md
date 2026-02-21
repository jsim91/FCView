# FCView App Features

## Application Tabs

| Tab | Purpose |
|---|---|
| Home | Upload data, dataset overview, metadata preview |
| Global Settings | Feature visibility, type coercion, pairing, subsetting, data export |
| UMAP | Embedding visualization and faceting |
| tSNE | Embedding visualization and faceting |
| Annotation | Cluster heatmap and cluster-to-celltype annotation engine |
| Collections | Define named subsets of clusters/celltypes for use in analyses |
| Testing | Non-parametric abundance testing across categorical/continuous metadata |
| Categorical | Per-entity abundance boxplot/violin plots with group comparisons |
| Continuous | Per-entity abundance scatter plots with continuous metadata correlation |
| Feature Selection | Variable importance filtering via Ridge, Elastic Net, or Boruta |
| Classification | Binary outcome modeling with multiple classifiers and validation strategies |
| Regression | Continuous outcome modeling with multiple regressors and validation strategies |
| sccomp | Bayesian differential composition analysis |
| Time to Event | Cox proportional hazards survival modeling |

---

## General Features

- **Data Upload**: load an `.RData` object produced by FCSimple containing `data`, `source`, `metadata`, and `cluster` fields.
- **Automatic Initialization**: parse, validate, and initialize expression, per-cell metadata, per-sample metadata, cluster assignments, embeddings, and abundance/count matrices on upload.
- **Dataset Preview**: display detected metadata features with data type and example values on the Home tab.
- **Downsampling**: optional per-upload cell downsampling (`max_cells_upload`) with deterministic seed and notification.
- **Metadata Mapping**: coherent mapping of per-sample metadata with per-cell metadata throughout the app.
- **Metadata Feature Quick Actions**: hide features from downstream UI or override data types (continuous ↔ categorical) per feature using the Global Settings mini UI.
- **Subsetting Rules**: build, apply, preview, and export per-sample subsetting rules using numeric operators and categorical value pickers; combine rules with AND/OR logic.
- **Pairing Support**: select the metadata variable that identifies matched samples/patients across conditions for paired statistical testing.
- **Paired Testing Autodetection**: app backend checks pairing feasibility in real-time and updates available test choices accordingly.
- **Tab Locking**: all tabs are disabled during data upload and re-enabled only after successful initialization to prevent invalid interactions.
- **Status Indicators**: reactive `output` flags (`hasResults`, `hasSubset`, `hasSccompResults`, etc.) drive conditional panels, download buttons, and tab availability.
- **User Notifications**: `showNotification` provides real-time feedback on status, errors, and warnings throughout the app.

---

## Comprehensive Features & Backend References

### Input Validation & Loading

- **Structured Input Detection**: accepts `.RData` containing at least `data`, `source`, `metadata`, and `cluster`; warns on multiple or missing matches.
- **Environment-safe Load**: loads into a temporary environment and places list elements into either a reactive or static context as appropriate.
- **Embedding Handling**: automatically converts matrix embeddings to `data.frame` for UMAP and tSNE plotting.
- **Downsampling on Upload**: configurable `max_cells_upload` threshold; deterministic sampling with seed and notifications.
- **Comprehensive Sanity Checks**: validates `patient_ID`, abundance row names, counts matrix presence, and emits user-facing notifications.

### Data Structures & Caching

- **Per-Cell and Per-Sample Stores**: `rv$expr`, `rv$meta_cell`, `rv$meta_sample`, `rv$meta_sample_original`, `rv$meta_cached`.
- **Clusters & Mapping**: preserves `clusters` (assignments, settings, abundance), `cluster_map`, and `cluster_heat` objects.
- **Counts & Abundance**: retains `rv$counts_sample` for sccomp and `rv$abundance_sample` for frequency-based analyses.
- **Type Coercion State**: `rv$type_coercions` stores requested coercion per column; `type_coercion_changed` flags changes.
- **Mini UI Persistence**: `rv$mini_hide_states` persists per-feature hide toggles across UI interactions.

### Global Settings & Feature Controls

- **`features_dropdown`**: multi-select picker to choose which metadata columns to surface in downstream UI.
- **`features_mini_ui`**: per-selected-feature compact rows with a hide checkbox and type selector; `rv$available_features` is derived from these states.
- **Global Settings Summary**: live text summary of currently active feature types and hidden features.
- **Single Source of Truth**: `features_mini_ui` replaces legacy checkboxes — mini inputs persist directly into `rv` state.

### Type Coercion System

- **Validation**: `validate_coercions()` inspects column data and provides valid conversion paths.
- **Application**: `apply_coercion()` performs data type conversions; coercions are applied only to exposed features (excludes `run_date` and `patient_ID`).
- **Real-time Effects**: testing and modeling method choices are updated when data types change.
- **Coercion Safety**: when coercions change, `pairing_var` and all subsetting rules are reset and the user is notified.

### Pairing & Paired-Testing Support

- **Pairing Variable Picker**: `pairing_var` updated with available metadata columns; selection is preserved where possible across state changes.
- **Feasibility Checks**: `test_can_pair()` and `cat_can_pair()` verify pairing feasibility given current data and subset.
- **UI Adaptation**: test selection UIs adapt to show paired tests only when pairing is both selected and feasible.
- **Incomplete Pair Trimming**: optional removal of samples with incomplete pairing by one or more categorical features, applied after subsetting rules.

### Subsetting Engine

- **Rule-based UI**: add multiple rules with stable IDs; supports numeric range operators and categorical multi-value pickers.
- **Dynamic Value UI**: numeric sliders and categorical value pickers render on-the-fly based on selected column type.
- **Apply & Preview**: intersection/union logic, subset preview showing sample distribution and a unique `subset_id`.
- **Exports**: `export_subset_meta`, `export_subset_frequencies`, and `export_subset_counts` write the current subset to CSV with rows aligned to `patient_ID`.

### Annotation Tab

- **Cluster Heatmap**: configurable color theme (viridis, heat, greyscale), optional row/column clustering, downloadable as PDF.
- **Cluster Annotation Engine**: define named cell types, assign clusters to them; annotations propagate throughout the app when "Celltypes" entity mode is selected.
- **Apply Annotations**: annotations are held in a working state until explicitly applied to prevent accidental overwrites.
- **Pre-fill from FCSimple**: when the uploaded object contains a `cluster_mapping` produced by `FCSimple::fcs_annotate_clusters()` and resolved by `fcs_prepare_fcview_object()`, the annotation UI is automatically pre-populated on upload with the existing cell type assignments; clusters with no assignment (`NA`) are safely excluded from the pre-fill.

### Collections Tab

- **Named Collections**: create named subsets of clusters or cell types to restrict analyses in Testing, Categorical, Continuous, Feature Selection, Classification, Regression, sccomp, and Time to Event tabs.
- **Working State**: collection edits are staged in a working state and only committed on "Update Collections".

### Testing Tab

- **Abundance Testing**: merges per-sample abundance with metadata, reshapes to long format, and runs non-parametric comparisons.
- **Supported Tests (unpaired)**: Wilcoxon rank-sum (Mann-Whitney U); Kruskal-Wallis for multi-group comparisons.
- **Supported Tests (paired)**: Wilcoxon signed-rank; Friedman test for multi-group paired comparisons.
- **P-value Adjustment**: BH, Bonferroni, BY, or FDR methods.
- **Entity Selection**: test by Clusters or Celltypes; restrict by collection.
- **Export**: test result table as CSV.

### Categorical Tab

- **Per-Entity Abundance Plots**: faceted boxplot or violin plots of cluster/celltype frequencies per categorical metadata group.
- **Statistical Overlay**: paired/unpaired significance testing with adjusted or raw p-values.
- **Custom Colors**: populate and edit group colors per metadata variable before generating plots.
- **Plot Options**: facet column count, show/hide x-axis labels, individual point overlay, plot type (box/violin).
- **Export**: PDF download of all generated plots.

### Continuous Tab

- **Per-Entity Scatter Plots**: faceted scatter plots correlating cluster/celltype frequencies with a continuous metadata variable.
- **Correlation**: computes and overlays correlation coefficients and p-values (adjusted or raw).
- **Axis Transposition**: optional axis swap for layout flexibility.
- **Export**: PDF download of all generated plots.

### Feature Selection Tab

- **Methods**: Ridge Regression, Elastic Net (tunable α slider), Random Forest via Boruta algorithm.
- **Inputs**: outcome variable, one or more predictors (including cluster/celltype frequency matrices), optional collection restriction.
- **Outputs**: selected feature summary table, variable importance plot, and console summary.
- **Export**: ZIP bundle with all results and figures.

### Classification Tab

- **Model Types**: Logistic Regression (with optional L1/L2/Elastic Net regularization), Elastic Net (standalone), Random Forest.
- **Regularization Options (Logistic)**: Lasso (L1), Ridge (L2), or Elastic Net (L1+L2); elastic net α tunable by slider.
- **Validation Strategies**: Train/Test split (configurable fraction), k-fold cross-validation (configurable k), Leave-One-Out CV.
- **Outputs**: ROC curve plot, AUC and performance metrics table, model summary, feature importance table.
- **Export**: ZIP bundle containing model summary, performance metrics, feature coefficients/importances, and the ROC plot; export filename reflects the model type and validation strategy captured at run time.

### Regression Tab

- **Model Types**: Linear Regression (with optional L1/L2/Elastic Net regularization), Ridge Regression (standalone), Elastic Net (tunable α), Random Forest.
- **Regularization Options (Linear)**: Lasso, Ridge, or Elastic Net; elastic net α tunable by slider.
- **Validation Strategies**: Train/Test split (configurable fraction), k-fold CV, Leave-One-Out CV.
- **Outputs**: observed vs predicted plot, residuals vs fitted plot, performance metrics (R², RMSE, MAE), model summary, feature importance table.
- **Export**: ZIP bundle with all results and figures; filename reflects model type and validation strategy captured at run time.

### sccomp Tab

- **Entity Selection**: test by Clusters or Celltypes; restrict by collection.
- **Formula Modes**:
  - *Simple*: pick a variable of interest (categorical or continuous), optional additional covariates (categorical or continuous), optional additive or interaction effects. The selected variable of interest is automatically excluded from the additional covariates picker to prevent duplicate formula terms.
  - *Custom*: free-text formula supporting fixed effects, interaction terms, random effects, and no-intercept formats.
- **Reference Level Control**:
  - *Simple mode*: dynamic reference level picker for the variable of interest (hidden automatically for continuous variables); free-text reference level input for additional covariates using `variable=level; variable2=level2` syntax.
  - *Custom mode*: free-text reference level input with the same syntax.
- **Inference Method**: Pathfinder (fast), HMC (most accurate), or Variational (intermediate).
- **Core Control**: slider for parallel computation cores.
- **Logit Fold-Change Threshold**: slider (0.1–1, step 0.05) controlling the minimum compositional change on the logit scale required for a cell group to be considered significant; applies to both the automatic and post-hoc contrast tests.
- **Execution**: runs `sccomp_estimate()` then automatically runs `sccomp_test()`.
- **Post-hoc Contrasts**: run explicit contrasts from the current estimate result using backtick-quoted parameter names.
- **Results Display**: text summary, credible interval plots (one per model term), contrast interval plots; plot titles automatically strip variable name prefixes for categorical levels while preserving full names for continuous variables.
- **Exports**: sccomp test CSV, contrast CSV, interval plot PDF, contrast interval plot PDF.

### Time to Event Tab

- **Model**: Cox proportional hazards regression via `survival::coxph` or penalized `glmnet`.
- **Analysis Modes**: Multivariate (all predictors in one model) or Univariate (one model per predictor with selector for result display).
- **Regularization (Multivariate)**: optional Lasso, Ridge, or Elastic Net penalty with tunable α.
- **Event Status Specification**: two paths:
  - *Metadata column*: select a binary/logical/text column encoding event status; for text columns, select which values represent the event (all others treated as censored).
  - *Manual selection*: pick individual sample IDs and mark them as events or censored.
- **Default Behavior**: when no event status is specified, all samples are treated as fully observed (event occurred).
- **Visualization**: Kaplan-Meier curve split by median or mean risk score, configurable CI display, custom colors for low/high risk groups.
- **Outputs**: KM curve, model summary, performance metrics table, coefficient/hazard ratio table.
- **Export**: ZIP bundle with all results and figures.

### Embeddings (UMAP / tSNE)

- **Display**: renders UMAP or tSNE embeddings from the uploaded object.
- **Faceting**: tile plots by a categorical metadata feature with equal per-group cell sampling to prevent overrepresentation bias.
- **Export**: PDF download of rendered embedding facets.

### User Experience & Robustness

- **Try/Catch Guards**: defensive `tryCatch` wrapping around UI updates to suppress errors when inputs are not yet available.
- **Persistent Metadata Description**: Home tab metadata table held in a static context as a reference throughout the session.
- **`patient_ID` Exclusion**: excluded from coercion, feature selection, and all picker lists.
- **Reset Behavior**: changing feature visibility or type via the mini UI resets pairing and clears subsetting to prevent unexpected downstream behavior.
- **Result State Caching**: all model/test results are stored in `reactiveVal` state objects; download handlers read run-time values (model type, validation strategy, outcome) captured at execution time rather than live inputs.
- **Session Save/Restore**: the full app state (active features, type coercions, pairing variable, subsetting rules, annotations, collections, and all analysis tab settings) can be saved to a timestamped `.json` file from the Home tab and restored in a future session after re-uploading the same `.RData` file.

### Exporting & Reporting

- **Download Handlers**: subset metadata CSV, cluster frequencies CSV, cluster counts CSV, sccomp results CSV, sccomp contrast CSV, sccomp interval plot PDF, sccomp contrast plot PDF, categorical plots PDF, continuous plots PDF, cluster heatmap PDF, UMAP/tSNE facet PDF, feature selection ZIP, classification ZIP, regression ZIP, time-to-event ZIP, session state `.json`.
- **Human-Readable Summaries**: `global_settings_summary`, pairing summaries, subsetting preview, and model console summaries provide concise overviews of current app state.
