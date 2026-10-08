# Forecast-in-a-box deployment

Deployment repository for metno's [forecast-in-a-box (fiab)](https://github.com/ecmwf/forecast-in-a-box) setup. Meant for setting up in minimal environments, such as a single gpu-enabled computer.

Having a separate deployment repository gives some benefits:

* Pack our own configuration into a single, standarized place
* Roll out custom-made and non-released versions of fiab wihtout waiting for upstream 


## Getting started

```bash
docker compose up --build
```

...then open up localhost:8000 in your browser.

Note that in the current setup, fiab will start with no models and no plugins installed. Models from metno's own model repository is available for download.
