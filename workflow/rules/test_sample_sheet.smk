rule create_samplesheet:
    output:
        "config/samplesheet.yaml"  # Path to the generated samplesheet
    run:
        import yaml
        # Extract sample names from the SAMPLES dictionary
        sample_data = {sample: {"name": sample} for sample in SAMPLES.keys()}
        
        # Write the sample data to a YAML file
        with open(output[0], "w") as f:
            yaml.dump(sample_data, f, default_flow_style=False)
