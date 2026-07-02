# Modeling Source Placeholder

Model fitting and prediction code belongs here.

The default model is:

```text
E_total = E_const + E_static + E_dynamic
A x = b
```

Use non-negative least squares by default.

The first implementation must follow `docs/design-spec/modeling.md`:

- constant power from idle baseline,
- static power from full-SM active-no-op baseline minus idle,
- dynamic energy as measured energy after subtracting constant/static,
- no occupancy/static scaling unless a later execution plan introduces it.
