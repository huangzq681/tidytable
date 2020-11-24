
<!-- README.md is generated from README.Rmd. Please edit that file -->

# tidytable <img src="man/figures/logo.png" align="right" width="17%" height="17%" />

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/tidytable)](https://cran.r-project.org/package=tidytable)
[![](https://img.shields.io/badge/dev%20-0.5.6.9-green.svg)](https://github.com/markfairbanks/tidytable)
[![Lifecycle:
maturing](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://www.tidyverse.org/lifecycle/#maturing)
[![CRAN RStudio mirror
downloads](https://cranlogs.r-pkg.org/badges/last-month/tidytable?color=grey)](https://markfairbanks.github.io/tidytable/)
<!-- badges: end -->

#### Why `tidytable`?

  - `tidyverse`-like syntax with `data.table` speed
  - `rlang` compatibility
  - Includes functions that `dtplyr` is missing, including many `tidyr`
    functions

Note: `tidytable` functions do not use `data.table`’s
modify-by-reference, and instead use the copy-on-modify principles
followed by the `tidyverse` and base R.

## Installation

Install the released version from [CRAN](https://CRAN.R-project.org)
with:

``` r
install.packages("tidytable")
```

Or install the development version from [GitHub](https://github.com/)
with:

``` r
# install.packages("devtools")
devtools::install_github("markfairbanks/tidytable")
```

## General syntax

`tidytable` uses `verb.()` syntax to replicate `tidyverse` functions:

``` r
library(tidytable)

test_df <- data.table(x = c(1,2,3), y = c(4,5,6), z = c("a","a","b"))

test_df %>%
  select.(x, y, z) %>%
  filter.(x < 4, y > 1) %>%
  arrange.(x, y) %>%
  mutate.(double_x = x * 2,
          double_y = y * 2)
#> # tidytable [3 × 5]
#>       x     y z     double_x double_y
#>   <dbl> <dbl> <chr>    <dbl>    <dbl>
#> 1     1     4 a            2        8
#> 2     2     5 a            4       10
#> 3     3     6 b            6       12
```

A full list of functions can be found
[here](https://markfairbanks.github.io/tidytable/reference/index.html).

## Using “group by”

Group by calls are done from inside any function that has group by
functionality (such as `summarize.()` & `mutate.()`)

  - A single column can be passed with `.by = z`
  - Multiple columns can be passed with `.by = c(y, z)`

<!-- end list -->

``` r
test_df %>%
  summarize.(avg_x = mean(x),
             count = n.(),
             .by = z)
#> # tidytable [2 × 3]
#>   z     avg_x count
#>   <chr> <dbl> <int>
#> 1 a       1.5     2
#> 2 b       3       1
```

##### `.by` vs. `group_by()`

A key difference between `tidytable`/`data.table` & `dplyr` is that
`dplyr` can chain multiple functions with a single `group_by()` call:

``` r
library(dplyr)

test_df <- tibble(x = 1:5, y = c("a", "a", "a", "b", "b"))

test_df %>%
  group_by(y) %>%
  mutate(avg_x = mean(x)) %>%
  slice(1:2) %>%
  ungroup()
#> # A tibble: 4 x 3
#>       x y     avg_x
#>   <int> <chr> <dbl>
#> 1     1 a       2  
#> 2     2 a       2  
#> 3     4 b       4.5
#> 4     5 b       4.5
```

In this case both `mutate()` and `slice()` will operate “by group”. This
happens until you call `ungroup()` at the end of the pipe chain.

However `data.table` doesn’t “remember” groups between function calls,
so this code would be written like this in `tidytable`:

``` r
test_df %>%
  mutate.(avg_x = mean(x), .by = y) %>%
  slice.(1:2, .by = y)
#> # tidytable [4 × 3]
#>       x y     avg_x
#>   <int> <chr> <dbl>
#> 1     1 a       2  
#> 2     2 a       2  
#> 3     4 b       4.5
#> 4     5 b       4.5
```

Note how `.by` is called in both `mutate.()` and `slice.()`, and you
don’t need to use `ungroup()` at the end.

## `tidyselect` support

`tidytable` allows you to select/drop columns just like you would in the
tidyverse by utilizing the [`tidyselect`](https://tidyselect.r-lib.org)
package in the background.

Normal selection can be mixed with all `tidyselect` helpers:
`everything()`, `starts_with()`, `ends_with()`, `any_of()`, `where()`,
etc.

``` r
test_df <- data.table(a = c(1,2,3),
                      b = c(4,5,6),
                      c = c("a","a","b"),
                      d = c("a","a","b"))

test_df %>%
  select.(a, b)
#> # tidytable [3 × 2]
#>       a     b
#>   <dbl> <dbl>
#> 1     1     4
#> 2     2     5
#> 3     3     6
```

To drop columns use a `-` sign:

``` r
test_df %>%
  select.(-a, -b)
#> # tidytable [3 × 2]
#>   c     d    
#>   <chr> <chr>
#> 1 a     a    
#> 2 a     a    
#> 3 b     b
```

These same ideas can be used whenever selecting columns in `tidytable`
functions - for example when using `count.()`, `drop_na.()`,
`mutate_across.()`, `pivot_longer.()`, etc.

`tidyselect` helpers also work when using `.by`:

``` r
test_df %>%
  summarize.(avg_b = mean(b), .by = where(is.character))
#> # tidytable [2 × 3]
#>   c     d     avg_b
#>   <chr> <chr> <dbl>
#> 1 a     a       4.5
#> 2 b     b       6
```

A full overview of selection options can be found
[here](https://tidyselect.r-lib.org/reference/language.html).

## `rlang` compatibility

`rlang` can be used to write custom functions with `tidytable`
functions:

``` r
df <- data.table(x = c(1,1,1), y = c(1,1,1), z = c("a","a","b"))

# Using enquo() with !!
add_one <- function(data, add_col) {
  
  add_col <- enquo(add_col)
  
  data %>%
    mutate.(new_col = !!add_col + 1)
}

# Using the {{ }} shortcut
add_one <- function(data, add_col) {
  data %>%
    mutate.(new_col = {{ add_col }} + 1)
}

df %>%
  add_one(x)
#> # tidytable [3 × 4]
#>       x     y z     new_col
#>   <dbl> <dbl> <chr>   <dbl>
#> 1     1     1 a           2
#> 2     1     1 a           2
#> 3     1     1 b           2
```

## Auto-conversion

All `tidytable` functions automatically convert `data.frame` and
`tibble` inputs to a `data.table`:

``` r
library(dplyr)
library(data.table)

test_df <- tibble(x = c(1,2,3), y = c(4,5,6), z = c("a","a","b"))

test_df %>%
  mutate.(double_x = x * 2) %>%
  is.data.table()
#> [1] TRUE
```

## `dt()` helper

The `dt()` function makes regular `data.table` syntax pipeable, so you
can easily mix `tidytable` syntax with `data.table` syntax:

``` r
df <- data.table(x = c(1,2,3), y = c(4,5,6), z = c("a", "a", "b"))

df %>%
  dt(, list(x, y, z)) %>%
  dt(x < 4 & y > 1) %>%
  dt(order(x, y)) %>%
  dt(, double_x := x * 2) %>%
  dt(, list(avg_x = mean(x)), by = z)
#> # tidytable [2 × 2]
#>   z     avg_x
#>   <chr> <dbl>
#> 1 a       1.5
#> 2 b       3
```

## Speed Comparisons

For those interested in performance, speed comparisons can be found
[here](https://markfairbanks.github.io/tidytable/articles/speed_comparisons.html).
