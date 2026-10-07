import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

commands = (
    """DROP SCHEMA IF EXISTS bronze CASCADE;""",

    """CREATE SCHEMA bronze;""",

    """CREATE TABLE bronze.listings (
        listing_id TEXT,
        scrape_id TEXT,
        scraped_date TEXT,
        host_id TEXT,
        host_name TEXT,
        host_since TEXT,
        host_is_superhost TEXT,
        host_neighbourhood TEXT,
        listing_neighbourhood TEXT,
        property_type TEXT,
        room_type TEXT,
        accommodates TEXT,
        price TEXT,
        has_availability TEXT,
        availability_30 TEXT,
        number_of_reviews TEXT,
        review_scores_rating TEXT,
        review_scores_accuracy TEXT,
        review_scores_cleanliness TEXT,
        review_scores_checkin TEXT,
        review_scores_communication TEXT,
        review_scores_value TEXT,
        source_file TEXT
    );""",

    """CREATE TABLE bronze.census_g01 (
        lga_code_2016 TEXT,
        tot_p_m TEXT,
        tot_p_f TEXT,
        tot_p_p TEXT,
        age_0_4_yr_m TEXT,
        age_0_4_yr_f TEXT,
        age_0_4_yr_p TEXT,
        age_5_14_yr_m TEXT,
        age_5_14_yr_f TEXT,
        age_5_14_yr_p TEXT,
        age_15_19_yr_m TEXT,
        age_15_19_yr_f TEXT,
        age_15_19_yr_p TEXT,
        age_20_24_yr_m TEXT,
        age_20_24_yr_f TEXT,
        age_20_24_yr_p TEXT,
        age_25_34_yr_m TEXT,
        age_25_34_yr_f TEXT,
        age_25_34_yr_p TEXT,
        age_35_44_yr_m TEXT,
        age_35_44_yr_f TEXT,
        age_35_44_yr_p TEXT,
        age_45_54_yr_m TEXT,
        age_45_54_yr_f TEXT,
        age_45_54_yr_p TEXT,
        age_55_64_yr_m TEXT,
        age_55_64_yr_f TEXT,
        age_55_64_yr_p TEXT,
        age_65_74_yr_m TEXT,
        age_65_74_yr_f TEXT,
        age_65_74_yr_p TEXT,
        age_75_84_yr_m TEXT,
        age_75_84_yr_f TEXT,
        age_75_84_yr_p TEXT,
        age_85ov_m TEXT,
        age_85ov_f TEXT,
        age_85ov_p TEXT,
        counted_census_night_home_m TEXT,
        counted_census_night_home_f TEXT,
        counted_census_night_home_p TEXT,
        count_census_nt_ewhere_aust_m TEXT,
        count_census_nt_ewhere_aust_f TEXT,
        count_census_nt_ewhere_aust_p TEXT,
        indigenous_psns_aboriginal_m TEXT,
        indigenous_psns_aboriginal_f TEXT,
        indigenous_psns_aboriginal_p TEXT,
        indig_psns_torres_strait_is_m TEXT,
        indig_psns_torres_strait_is_f TEXT,
        indig_psns_torres_strait_is_p TEXT,
        indig_bth_abor_torres_st_is_m TEXT,
        indig_bth_abor_torres_st_is_f TEXT,
        indig_bth_abor_torres_st_is_p TEXT,
        indigenous_p_tot_m TEXT,
        indigenous_p_tot_f TEXT,
        indigenous_p_tot_p TEXT,
        birthplace_australia_m TEXT,
        birthplace_australia_f TEXT,
        birthplace_australia_p TEXT,
        birthplace_elsewhere_m TEXT,
        birthplace_elsewhere_f TEXT,
        birthplace_elsewhere_p TEXT,
        lang_spoken_home_eng_only_m TEXT,
        lang_spoken_home_eng_only_f TEXT,
        lang_spoken_home_eng_only_p TEXT,
        lang_spoken_home_oth_lang_m TEXT,
        lang_spoken_home_oth_lang_f TEXT,
        lang_spoken_home_oth_lang_p TEXT,
        australian_citizen_m TEXT,
        australian_citizen_f TEXT,
        australian_citizen_p TEXT,
        age_psns_att_educ_inst_0_4_m TEXT,
        age_psns_att_educ_inst_0_4_f TEXT,
        age_psns_att_educ_inst_0_4_p TEXT,
        age_psns_att_educ_inst_5_14_m TEXT,
        age_psns_att_educ_inst_5_14_f TEXT,
        age_psns_att_educ_inst_5_14_p TEXT,
        age_psns_att_edu_inst_15_19_m TEXT,
        age_psns_att_edu_inst_15_19_f TEXT,
        age_psns_att_edu_inst_15_19_p TEXT,
        age_psns_att_edu_inst_20_24_m TEXT,
        age_psns_att_edu_inst_20_24_f TEXT,
        age_psns_att_edu_inst_20_24_p TEXT,
        age_psns_att_edu_inst_25_ov_m TEXT,
        age_psns_att_edu_inst_25_ov_f TEXT,
        age_psns_att_edu_inst_25_ov_p TEXT,
        high_yr_schl_comp_yr_12_eq_m TEXT,
        high_yr_schl_comp_yr_12_eq_f TEXT,
        high_yr_schl_comp_yr_12_eq_p TEXT,
        high_yr_schl_comp_yr_11_eq_m TEXT,
        high_yr_schl_comp_yr_11_eq_f TEXT,
        high_yr_schl_comp_yr_11_eq_p TEXT,
        high_yr_schl_comp_yr_10_eq_m TEXT,
        high_yr_schl_comp_yr_10_eq_f TEXT,
        high_yr_schl_comp_yr_10_eq_p TEXT,
        high_yr_schl_comp_yr_9_eq_m TEXT,
        high_yr_schl_comp_yr_9_eq_f TEXT,
        high_yr_schl_comp_yr_9_eq_p TEXT,
        high_yr_schl_comp_yr_8_belw_m TEXT,
        high_yr_schl_comp_yr_8_belw_f TEXT,
        high_yr_schl_comp_yr_8_belw_p TEXT,
        high_yr_schl_comp_d_n_g_sch_m TEXT,
        high_yr_schl_comp_d_n_g_sch_f TEXT,
        high_yr_schl_comp_d_n_g_sch_p TEXT,
        count_psns_occ_priv_dwgs_m TEXT,
        count_psns_occ_priv_dwgs_f TEXT,
        count_psns_occ_priv_dwgs_p TEXT,
        count_persons_other_dwgs_m TEXT,
        count_persons_other_dwgs_f TEXT,
        count_persons_other_dwgs_p TEXT
    );""",

    """CREATE TABLE bronze.census_g02 (
        lga_code_2016 TEXT,
        median_age_persons TEXT,
        median_mortgage_repay_monthly TEXT,
        median_tot_prsnl_inc_weekly TEXT,
        median_rent_weekly TEXT,
        median_tot_fam_inc_weekly TEXT,
        average_num_psns_per_bedroom TEXT,
        median_tot_hhd_inc_weekly TEXT,
        average_household_size TEXT
    );""",

    """CREATE TABLE bronze.lga_codes (
        lga_code TEXT,
        lga_name TEXT
    );""",

    """CREATE TABLE bronze.suburb_lga_mapping (
        lga_name TEXT,
        suburb_name TEXT
    );""",
)

if __name__ == '__main__':
    conn = None
    try:
        conn = psycopg2.connect(
            host=os.getenv('POSTGRES_HOST'),
            database=os.getenv('POSTGRES_DATABASE'),
            user=os.getenv('POSTGRES_USER'),
            password=os.getenv('POSTGRES_PASSWORD')
        )
        cur = conn.cursor()
        for command in commands:
            cur.execute(command)
        cur.close()
        conn.commit()
        print("Tables created successfully in the 'bronze' schema.")
    except Exception as e:
        print(f"Error creating tables: {e}")
    finally:
        if conn is not None:
            conn.close()