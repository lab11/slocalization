function best_seq = generate_calibrated_dynamic_seq(measured_amps_dbm)

measured_amps = 10.^(measured_amps_dbm./20);
desired_amps = max(measured_amps)./measured_amps;
desired_amps(1) = 0;
best_seq = generate_min_dynamic_seq(desired_amps);
