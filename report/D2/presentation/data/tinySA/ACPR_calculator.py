import pandas as pd
import numpy as np

def calculate_acpr(file_list, main_band, lower_band, upper_band):
    """
    Calculates ACPR for a list of CSV files.
    
    Parameters:
    - main_band: (start_f, stop_f) in MHz
    - lower_band: (start_f, stop_f) in MHz
    - upper_band: (start_f, stop_f) in MHz
    """
    results = []

    for file in file_list:
        # Load CSV: Expects Col 0 = Freq (MHz), Col 1 = Power (dBm)
        df = pd.read_csv(file, header=None, names=['freq', 'dbm'])
        
        # Convert dBm to linear power (mW)
        df['mw'] = 10 ** (df['dbm'] / 10)

        def get_total_power(band):
            mask = (df['freq'] >= band[0]) & (df['freq'] <= band[1])
            return df.loc[mask, 'mw'].sum()

        # Calculate power in each segment
        p_main = get_total_power(main_band)
        p_lower = get_total_power(lower_band)
        p_upper = get_total_power(upper_band)

        # ACPR Calculation in dBc
        acpr_lower = 10 * np.log10(p_lower / p_main)
        acpr_upper = 10 * np.log10(p_upper / p_main)
        acpr_total = 10 * np.log10((p_lower + p_upper) / (2 *p_main))

        results.append({
            "File": file,
            "Lower ACPR (dBc)": round(acpr_lower, 2),
            "Upper ACPR (dBc)": round(acpr_upper, 2),
            "Total ACPR (dBc)": round(acpr_total, 2),
        })

    return pd.DataFrame(results)

# Files
csv_files = ['MOD-10.csv', 'MOD-12.csv', 'MOD-15.csv', 'MOD-17.csv', 'MOD-20.csv']
 
# Frequecy ranges in MHz
main_range  = (2385, 2415)  # Useful Band
lower_range = (2355, 2385)  # Lower Sideband
upper_range = (2415, 2445)  # Upper Sideband

# Run calculation
report = calculate_acpr(csv_files, main_range, lower_range, upper_range)

print("ACPR Measurement Report")
print(report.to_string(index=False))