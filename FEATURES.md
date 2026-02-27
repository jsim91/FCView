# FCView App Features

## Application Tabs

| Tab | Purpose |
|---|---|
| Home | Upload data, dataset overview, metadata preview, session state save/restore |
| Subsetting | Pairing variable, subsetting rules, incomplete pair trimming, data export |
| Edit Features | Feature visibility, type coercion, feature transforms, feature derivations, N-level interval categorization, distribution preview |
| UMAP | Embedding visualization and faceting |
| tSNE | Embedding visualization and faceting |
| Annotation | Cluster heatmap and cluster-to-celltype annotation engine |
| Collections | Define named subsets of clusters/celltypes for use in analyses |
| Testing | Non-parametric abundance testing across categorical/continuous metadata |
| Categorical | Per-entity abundance boxplot/violin plots with group comparisons |
| Continuous | Per-entity abundance scatter plots with continuous metadata correlation |
| Feature Selection | Variable importance filtering via Ridge, Elastic Net, or Boruta |
| Classification | Binary/multiclass outcome modeling with multiple classifiers and validation strategies |
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
- **Metadata Feature Management**: hide features from downstream UI, override data types (continuous ↔ categorical), add derived/transformed columns, and preview distributions — all in the Edit Features tab.
- **Subsetting Rules**: build, apply, preview, and export per-sample subsetting rules using numeric operators and categorical value pickers; combine rules with AND/OR logic.
- **Pairing Support**: select the metadata variable that identifies matched samples/patients across conditions for paired statistical testing; picker is restricted to categorical non-hidden columns.
- **Paired Testing Autodetection**: app backend checks pairing feasibility in real-time and updates available test choices accordingly.
- **Session Save/Restore**: the full app state can be saved to a timestamped `.json` file and restored in a future session after re-uploading the same `.RData` file. Save/restore controls are on the Home tab.
- **Tab Locking**: all tabs are disabled during data upload and re-enabled only after successful initialization to prevent invalid interactions.
- **Status Indicators**: reactive `output` flags drive conditional panels, download buttons, and tab availability.
- **User Notifications**: `showNotification` provides real-time feedback on status, errors, and warnings throughout the app.

---

## Comprehensive Features & Backend References

### Input Validation & Loading

- **Structured Input Detection**: accepts `.RData` containing at least `data`, `source`, `metadata`, and `cluster`; warns on multiple or missing matches.
- **Environment-safe Load**: loads into a temporary environment and places list elements into either a reactive or static context as appropriate.
- **Embedding Handling**: automatically converts matrix embeddings to `data.frame` for UMAP and tSNE plotting.
- **Downsampling on Upload**: configurable `max_cells_upload` threshold; deterministic sampling with seed and notifications.
- **Comprehensive Sanity Checks**: validates `patient_ID`, abundance row names, counts matrix presence, and emits user-facing notifications.
- **`run_date` Propagation**: `run_date` (when present in per-cell metadata) is joined onto per-sample metadata and made available as a grouping/batch variable throughout the app.

### Data Structures & Caching

- **Per-Cell and Per-Sample Stores**: `rv$expr`, `rv$meta_cell`, `rv$meta_sample`, `rv$meta_sample_original`, `rv$meta_cached`.
- **Clusters & Mapping**: preserves `clusters` (assignments, settings, abundance), `cluster_map`, and `cluster_heat` objects.
- **Counts & Abundance**: retains `rv$counts_sample` for sccomp and `rv$abundance_sample` for frequency-based analyses.
- **Type Coercion State**: `rv$type_coercions` stores requested coercion per column; `type_coercion_changed` flags changes.
- **Mini UI Persistence**: `rv$mini_hide_states` persists per-feature hide toggles across UI interactions.
- **Feature Transforms & Derivations**: `rv$feature_transforms`, `rv$feature_derivations`, and `rv$feature_categorizations` store all user-defined derived columns; new columns are written into `rv$meta_cached` so they are available across all downstream analyses before subsetting is evaluated.

### Edit Features Tab

#### Feature Type Coercion & Visibility

- **`features_dropdown`**: multi-select picker to choose which metadata columns to surface in downstream UI.
- **`features_mini_ui`**: per-selected-feature compact rows with a hide checkbox and type selector; `rv$available_features` is derived from these states.
- **Single Source of Truth**: mini inputs persist directly into `rv` state on change; a per-column `identical()` guard prevents spurious reactive cascades.
- **Validation**: `validate_coercions()` inspects column data and provides valid conversion paths; `apply_coercion()` applies changes (excludes `run_date` and `patient_ID`).
- **Real-time Effects**: testing and modeling method choices update when data types change.
- **Targeted Reset on Hide/Type Change**: hiding a feature or changing its type resets only the pairing variable and subsetting rules that reference that specific column; unrelated rules and pickers are not disturbed.

#### Transform a Feature

- **Supported Transforms**: natural log (`ln`, uses `log()` internally), log₂, log₁₀, logₙ (custom base), square root, absolute value, z-score, inverse (1/x), square, cube.
- **Output Naming**: new column is named `<source>_<suffix>` (e.g. `age_ln`, `cd4_log2`, `il6_zscore`).
- **Zero-Detection**: log transforms automatically detect zeros in non-NA values, apply a `+1` shift before transforming, and append `_p1` to the suffix (e.g. `age_ln_p1`). A warning notification is shown.
- **NA Preservation**: `apply_transform_fn()` restores NAs explicitly after transformation, preventing NA→NaN silent coercion.
- **Active Transforms List**: each active transform is listed with a label `(<source> → <transform>)` — natural log displays as `ln` for clarity — and a trash-button for removal.
- **Remove Behavior**: removing a transform deletes the derived column from `rv$meta_cached` and all downstream metadata structures.

#### Derive a Feature

- **Supported Operators**: A÷B, A×B, A+B, A−B, A^B, log(A/B).
- **Output Naming**: `<featureA>_<op>_<featureB>` (e.g. `cd4_div_cd8`, `tnf_lograt_il6`).
- **Input Restriction**: Feature A and Feature B pickers are restricted to continuous (numeric) columns only to prevent nonsensical operations on categorical data.
- **Active Derivations List**: each derivation is listed with its expression and a remove button.

#### Categorize a Feature

- **Purpose**: convert a continuous numeric feature into an N-level ordered categorical feature by defining a set of interval boundaries — e.g. classify HbA1c into `"no_diabetes"`, `"pre_diabetes"`, `"diabetes"` using two thresholds.
- **Interval Builder**: a dynamic row-based UI where each non-last row specifies an exclusive upper bound and a category label; the last row is unbounded (captures all remaining values). Rows can be added or removed; a minimum of two categories (one boundary) is required.
- **Snap-to Controls**: each upper bound row includes a dropdown to snap the bound to a data-driven statistic computed from the selected source feature: Median (50%), Mean, Q1 (25%), Q3 (75%), 33rd percentile, 67th percentile. After snapping, the dropdown resets to "Custom" so the label accurately reflects the editable state.
- **Inline Validation**: the Interval column shows a red warning immediately when any row's upper bound is ≤ the previous row's bound (out-of-order), giving instant visual feedback before the feature is committed.
- **Output Naming**: `<source>_cat_<N>lvl` where N is the number of categories (e.g. `hba1c_cat_3lvl`).
- **NA Preservation**: rows where the source feature is `NA` remain `NA` in the new column.
- **Commit Validation**: upper bounds must be strictly increasing; all labels must be non-empty and unique; a column with the derived name must not already exist.
- **Implementation**: uses `cut(..., right = FALSE, include.lowest = TRUE)` with `breaks = c(-Inf, <user bounds>, Inf)` so intervals are left-closed: `[lower, upper)`.
- **Result**: the new column is a character vector and immediately appears in all categorical pickers throughout the app (Subsetting, Testing, Classification, etc.).
- **Active Categorizations List**: each committed categorization is listed showing the full interval rule string (e.g. `< 5.7 → 'no_diabetes'; 5.7 to < 6.5 → 'pre_diabetes'; ≥ 6.5 → 'diabetes'`) and a remove button.
- **Session Save/Restore**: categorizations are saved as `{source, breaks, labels}` triplets and reconstructed on restore; the old binary format (`threshold / above_label / below_label`) is automatically migrated on load for backward compatibility.

#### Rename a Feature

- **Custom Display Names**: each metadata feature can be assigned a custom display name via the Edit Features tab. The internal column name is preserved unchanged; the display name is purely cosmetic.
- **Universal Propagation**: all `updatePickerInput` calls throughout every analysis tab (Feature Selection, Classification, Regression, Testing, Categorical, Continuous, sccomp, Time to Event) use `make_labeled_choices()`, which reads `rv$feature_renames` reactively, so renaming a feature instantly updates every dropdown without requiring a manual refresh.
- **Dummy-Expanded Names**: for categorical features that produce dummy-expanded column names during modeling (e.g. `Age_spec_cat_2lvlolder`), `apply_feature_display_names()` uses a prefix-match fallback — it maps the base column to its display name and appends the level suffix (e.g. → `age groupolder`). Model coefficient tables in Classification, Regression, and TTE tabs therefore show renamed names even for expanded categorical levels.
- **sccomp Formula & Parameters**: before `sccomp_estimate` is called, renamed formula variables are written to the `sccomp_data` data frame under safe-name equivalents (spaces → underscores) and `formula_str` is updated with word-boundary replacement. The Results Summary formula and the Significant Clusters parameter column reflect custom display names.
- **TTE Univariate Dropdown**: the "Display results for:" selector shown after a univariate run applies `apply_feature_display_names()` to predictor names so renamed features appear with their display names in the result selector.
- **`make_labeled_choices(cols)`**: shared helper that returns a named character vector where names are display labels and values are the original column names; used by every picker that lists metadata columns.
- **`apply_feature_display_names(vec)`**: shared helper that maps a character vector of internal column names to their display names. Supports exact match and prefix-match (for dummy-expanded names); falls back to the original name when no rename is defined.
- **Session Save/Restore**: `rv$feature_renames` is saved to the session `.json` file as a named list and fully restored on load. All rename textInputs in the Edit Features tab are repopulated on restore and all pickers update immediately.

#### Preview Feature Distribution

- **Source Data**: reads from `rv$meta_sample` (the active subsetted dataset), so the preview always reflects current subsetting rules.
- **Histogram** with configurable bin count (default 25); optional empirical density overlay; optional fitted normal reference curve.
- **Subtitle Statistics**: n, mean, SD, skewness, and normality test result displayed inline.
- **Normality Testing**: Shapiro-Wilk for n ≤ 5000; Kolmogorov-Smirnov (vs. fitted normal) for larger samples. Result annotated with significance stars (`ns`, `*`, `**`, `***`).

### Subsetting Tab

- **Pairing Variable Picker**: restricted to categorical (character/factor) non-hidden columns only; automatically updates choices when features are hidden or type-coerced. Valid selection is preserved; the picker clears silently when the selected column is hidden or becomes non-categorical. A notification is shown only when the current selection is actively hidden.
- **Feasibility Checks**: `test_can_pair()` and `cat_can_pair()` verify pairing feasibility given current data and subset.
- **UI Adaptation**: test selection UIs adapt to show paired tests only when pairing is both selected and feasible.
- **Incomplete Pair Trimming**: optional removal of samples with incomplete pairing by one or more categorical features, applied after subsetting rules.
- **Rule-based UI**: add multiple rules with stable IDs; supports numeric range operators and categorical multi-value pickers.
- **Dynamic Value UI**: numeric sliders and categorical value pickers render on-the-fly based on selected column type.
- **Hidden Column Exclusion**: hidden features are excluded from subsetting rule column choices as well as from the pairing picker.
- **Apply & Preview**: intersection/union logic, subset preview showing sample distribution and a unique `subset_id`.
- **Exports**: `export_subset_meta`, `export_subset_frequencies`, and `export_subset_counts` write the current subset to CSV.

### Annotation Tab

- **Cluster Heatmap**: configurable color theme (viridis, heat, greyscale), optional row/column clustering, downloadable as PDF.
- **Cluster Annotation Engine**: define named cell types, assign clusters to them; annotations propagate throughout the app when "Celltypes" entity mode is selected.
- **Unassigned Handling**: clusters not assigned to any cell type are mapped to the string `"unassigned"` throughout all downstream computations (embeddings, aggregation, annotation pre-fill) rather than propagating `NA`.
- **Duplicate Cluster Warning**: saving annotations with any cluster appearing in more than one cell type group triggers a named warning notification listing the conflicting clusters.
- **Apply Annotations**: annotations are held in a working state until explicitly applied to prevent accidental overwrites.
- **Pre-fill from FCSimple**: when the uploaded object contains a `cluster_mapping`, the annotation UI is automatically pre-populated on upload; clusters with no assignment are safely excluded from the pre-fill.

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
- **Random Seed**: user-configurable integer seed for reproducible train/test splits and model fitting (default 42); stored in session state.
- **Performance Metrics Table**: all rows include an `Interpretation` column with plain-language descriptions.
- **Model Complexity Warning (EPV)**:
  - *Binary*: reports events-per-variable (EPV) = minority class count ÷ effective predictor count; thresholds at < 5 (WARNING), < 10 (CAUTION), ≥ 10 (ADEQUATE).
  - *Multiclass*: reports average samples per class per predictor; same thresholds.
  - *Effective predictor count*: for Lasso/Elastic Net (α > 0) models, counts only non-zero coefficients (|β| > 1e-10, intercept excluded); for Ridge (α = 0) and RF the full input count is used. Labels show both effective and input counts when they differ (e.g. `"effective p=5 (input p=12)"`).
- **Outputs**: ROC curve plot, AUC and performance metrics table, model summary, feature importance table.
- **Export**: ZIP bundle containing model summary, performance metrics, feature coefficients/importances, and the ROC plot.

### Regression Tab

- **Model Types**: Linear Regression (with optional L1/L2/Elastic Net regularization), Ridge Regression (standalone), Elastic Net (tunable α), Random Forest.
- **Regularization Options (Linear)**: Lasso, Ridge, or Elastic Net; elastic net α tunable by slider.
- **Validation Strategies**: Train/Test split (configurable fraction), k-fold CV, Leave-One-Out CV.
- **Random Seed**: user-configurable integer seed for reproducible train/test splits and model fitting (default 42); stored in session state.
- **Layout**: three diagnostic plots (Observed vs Predicted, Residuals vs Fitted, Residual Q-Q) on the top row; Model Summary and Performance Metrics table side-by-side below; Model Features table in the right column.
- **Performance Metrics Table**: all rows include an `Interpretation` column with plain-language descriptions.
- **Model Complexity Warning**: reports observations-per-predictor (n ÷ effective p); thresholds at < 5 (WARNING), < 10 (CAUTION), 10–20 (ADEQUATE), ≥ 20 (GOOD). Uses effective predictor count for Lasso/Elastic Net (same logic as Classification tab).
- **Homoskedasticity Check**: Spearman rank correlation of |residuals| vs fitted values; reports ρ and p-value; PASS (p > 0.05), MARGINAL (p < 0.05), FAIL (p < 0.01). Significant result indicates heteroskedasticity — variance changing with fitted values — which invalidates standard errors and p-values from linear models.
- **Residual Normality Check**: Shapiro-Wilk test (n ≤ 5000) reports W and p-value; for n > 5000 the test is skipped with a note to inspect the Q-Q plot. Required for valid inference (CIs, p-values) from linear models.
- **Residual Q-Q Plot**: normal quantile-quantile plot of residuals with reference line; systematic curvature indicates departure from normality.
- **Export**: ZIP bundle with all results and figures.

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

### Effective Predictor Count

- **`get_effective_n_predictors(res)`**: shared helper used by both Classification and Regression performance tables. For glmnet models with α > 0 (Lasso or Elastic Net), counts only predictors with |β| > 1e-10 (excluding the intercept; for multiclass, takes the union of non-zero predictors across all classes). For Ridge (α = 0), RF, and `lm`, falls back to the input predictor count stored in `res$n_predictors`. When effective ≠ input, metric labels show both counts (e.g. `"effective p=5 (input p=12)"`).

### Session Save / Restore

- **Saved State Includes**: active features, hide states, type coercions, **feature display name renames**, pairing variable, subsetting rules, annotations, collections, feature transforms, feature derivations, feature categorizations, and all analysis tab settings (entity, outcome, predictors, model type, validation strategy, regularization, seeds, colors, etc.).
- **Seeds Stored**: `lm_seed` (classification), `reg_seed` (regression), `surv_seed` (time-to-event) are saved and restored.
- **Backward Compatibility**: all fields use `%||%` fallback defaults; sessions saved before a field was added restore cleanly without error.
- **Restore Order**: derived feature columns are reconstructed before coercions are applied, which is before subsetting rules are evaluated, matching the normal data-flow order.
- **Rename Restore Race Guard**: a `rv$pending_dropdown_restore` reactiveVal stores the intended `features_dropdown` selection during restore; the `observeEvent(rv$meta_sample)` observer checks and consumes it after coercion re-apply completes, preventing the reactive cascade from clobbering the restored selection.
- **Controls Location**: Save/Restore buttons are on the Home tab sidebarPanel.

### User Experience & Robustness

- **Try/Catch Guards**: defensive `tryCatch` wrapping around UI updates to suppress errors when inputs are not yet available.
- **Per-Column Observer Guards**: `identical()` early-return check prevents mini UI re-renders from firing downstream effects when values haven't actually changed.
- **Persistent Metadata Description**: Home tab metadata table held in a static context as a reference throughout the session.
- **`patient_ID` and `run_date` Exclusion**: excluded from coercion, feature selection, and editable picker lists.
- **Targeted Reset on Feature Change**: hiding or type-coercing a feature resets only the pairing variable and subsetting rules that reference that specific column; unrelated state is not disturbed.
- **Result State Caching**: all model/test results are stored in `reactiveVal` state objects; download handlers read run-time values captured at execution time rather than live inputs.

### Exporting & Reporting

- **Download Handlers**: subset metadata CSV, cluster frequencies CSV, cluster counts CSV, sccomp results CSV, sccomp contrast CSV, sccomp interval plot PDF, sccomp contrast plot PDF, categorical plots PDF, continuous plots PDF, cluster heatmap PDF, UMAP/tSNE facet PDF, feature selection ZIP, classification ZIP, regression ZIP, time-to-event ZIP, session state `.json`.
- **Human-Readable Summaries**: pairing summaries, subsetting preview, and model console summaries provide concise overviews of current app state.
