
using IfElse
using SpecialFunctions
using ModelingToolkit
using DifferentialEquations
using DataInterpolations

#variables and parameters of the model (the variable/parameter name "t" is forbiden)
@variables t
D = Differential(t)
@parameters TIME_STEP =10
@parameters Output_in_1965 = 8.519e12 [description = "Output_in_1965"]
@parameters Red_Cost_Scale = 0.0686 [description = "Red_Cost_Scale"]
@parameters A_UO_Heat_Cap = 44.248 [description = "A_UO_Heat_Cap"]
@parameters one_year = 1.0 [description = "one_year"]
@parameters Climate_Sensitivity = 2.908 [description = "Climate_Sensitivity"]
@parameters Atmos_Retention = 0.64 [description = "Atmos_Retention"]
@parameters emissions_sensitivity = 0.0 [description = "emissions_sensitivity"]
@parameters init_Atmos_UOcean_Temp = 0.2 [description = "init_Atmos_UOcean_Temp"]
@parameters init_Deep_Ocean_Temp = 0.1 [description = "init_Deep_Ocean_Temp"]
@parameters Reduction_Start_Time = 2010.0 [description = "Reduction_Start_Time"]
@parameters Initial_Population = 3.369e9 [description = "Initial_Population"]
@parameters Preindustrial_CO2 = 5.9e11 [description = "Preindustrial_CO2"]
@parameters reference_emissions = 5.0e9 [description = "reference_emissions"]
@parameters Utility_Coeff = 1.0 [description = "Utility_Coeff"]
@parameters Rate_of_Time_Pref = 0.03 [description = "Rate_of_Time_Pref"]
@parameters Reference_Temperature = 3.0 [description = "Reference_Temperature"]
@parameters concentration_sensitivity = 0.0 [description = "concentration_sensitivity"]
@parameters Initial_Return_Trend = -0.00054 [description = "Initial_Return_Trend"]
@parameters Capital_Elast_Output = 0.25 [description = "Capital_Elast_Output"]
@parameters Depreciation_Rate = 0.065 [description = "Depreciation_Rate"]
@parameters Init_Fact_Prod_Growth_Rt = 0.015 [description = "Init_Fact_Prod_Growth_Rt"]
@parameters Rate_of_Inequal_Aversion = 1.0 [description = "Rate_of_Inequal_Aversion"]
@parameters Red_Cost_Nonlinearity = 2.887 [description = "Red_Cost_Nonlinearity"]
@parameters init_co2_intens_decline_rt = 0.01168 [description = "init_co2_intens_decline_rt"]
@parameters Init_Pop_Growth_Rate = 0.0223 [description = "Init_Pop_Growth_Rate"]
@parameters Ref_Cons_per_Cap = 1000.0 [description = "Ref_Cons_per_Cap"]
@parameters smoothing_time = 20.0 [description = "smoothing_time"]
@parameters Ultimate_Population = 1.0572e10 [description = "Ultimate_Population"]
@parameters CO2_Rad_Force_Coeff = 4.1 [description = "CO2_Rad_Force_Coeff"]
@parameters init_CO2_intensity_of_output = 0.000519 [description = "init_CO2_intensity_of_output"]
@parameters Climate_Damage_Nonlinearity = 2.0 [description = "Climate_Damage_Nonlinearity"]
@parameters Fact_Prod_Gr_Rt_Dec_Rt = 0.011 [description = "Fact_Prod_Gr_Rt_Dec_Rt"]
@parameters CO2_Transfer_Time = 120.0 [description = "CO2_Transfer_Time"]
@parameters Heat_Trans_Coeff = 500.0 [description = "Heat_Trans_Coeff"]
@parameters Base_Year = 1989.0 [description = "Base_Year"]
@parameters init_CO2_in_Atmos = 6.77e11 [description = "init_CO2_in_Atmos"]
@parameters constant_reduction = 0.0 [description = "constant_reduction"]
@parameters Initial_Capital = 1.6e13 [description = "Initial_Capital"]
@parameters Climate_Damage_Scale = 0.013 [description = "Climate_Damage_Scale"]
@parameters Heat_Capacity_Ratio = 0.44 [description = "Heat_Capacity_Ratio"]
@variables Deep_Ocean_Temp(t) = -1.0 [description = "Deep_Ocean_Temp"]
@variables Pop_Growth_Rate(t) = -1.0 [description = "Pop_Growth_Rate"]
@variables CO2_Intens_Decline_Rt(t) = -1.0 [description = "CO2_Intens_Decline_Rt"]
@variables CO2_Intensity_of_Output(t) = -1.0 [description = "CO2_Intensity_of_Output"]
@variables Capital(t) = -1.0 [description = "Capital"]
@variables Atmos_UOcean_Temp(t) = -1.0 [description = "Atmos_UOcean_Temp"]
@variables CO2_in_Atmos(t) = -1.0 [description = "CO2_in_Atmos"]
@variables Cum_Disc_Utility(t) = 0.0 [description = "Cum_Disc_Utility"]
@variables Population(t) = -1.0 [description = "Population"]
@variables Fact_Prod_Growth_Rt(t) = -1.0 [description = "Fact_Prod_Growth_Rt"]
@variables Factor_Productivity(t) = 1.0 [description = "Factor_Productivity"]
@variables Capital_Labor_Ratio(t)  [description = "Capital_Labor_Ratio"]
@variables Capital_Life(t)  [description = "Capital_Life"]
@variables Capital_Output_Ratio(t)  [description = "Capital_Output_Ratio"]
@variables Chg_A_UO_Temp(t)  [description = "Chg_A_UO_Temp"]
@variables Chg_DO_Temp(t)  [description = "Chg_DO_Temp"]
@variables Climate_Damage_Frac(t)  [description = "Climate_Damage_Frac"]
@variables Climate_Damages(t)  [description = "Climate_Damages"]
@variables Climate_Feedback_Param(t)  [description = "Climate_Feedback_Param"]
@variables CO2_Emiss(t)  [description = "CO2_Emiss"]
@variables CO2_Intens_Capital(t)  [description = "CO2_Intens_Capital"]
@variables CO2_Intens_Dec_Rt_Decline_Rt(t)  [description = "CO2_Intens_Dec_Rt_Decline_Rt"]
@variables CO2_Net_Emiss(t)  [description = "CO2_Net_Emiss"]
@variables CO2_Rad_Forcing(t)  [description = "CO2_Rad_Forcing"]
@variables CO2_Storage(t)  [description = "CO2_Storage"]
@variables TEMPVAR_Cons_Growth_Rate(t) = 0 # arbitrary value
@variables TEMPVARSMOOTHED_Cons_Growth_Rate(t) =  TEMPVAR_Cons_Growth_Rate [description = "TEMPVARSMOOTHED_Cons_Growth_Rate, created by the \"SMOOTH\" function or an afiliate"]
@variables Cons_Growth_Rate(t)  [description = "Cons_Growth_Rate"]
@variables Consumption(t)  [description = "Consumption"]
@variables Consumption_per_Cap(t)  [description = "Consumption_per_Cap"]
@variables Decline_CO2_Intens(t)  [description = "Decline_CO2_Intens"]
@variables Decline_Pop_Gr_Rt(t)  [description = "Decline_Pop_Gr_Rt"]
@variables Depreciation(t)  [description = "Depreciation"]
@variables Desired_Capital_Growth_Rate(t)  [description = "Desired_Capital_Growth_Rate"]
@variables Discount_Factor(t)  [description = "Discount_Factor"]
@variables Discounted_Utility(t)  [description = "Discounted_Utility"]
@variables DO_Heat_Cap(t)  [description = "DO_Heat_Cap"]
@variables Expected_Return(t)  [description = "Expected_Return"]
@variables TEMPVAR_Expected_Return_Trend(t) = -0.00054
 #arbitrary value 
@variables TEMPVARSMOOTHED_Expected_Return_Trend(t) = (TEMPVAR_Expected_Return_Trend) [description = "TEMPVARSMOOTHED_Expected_Return_Trend, created by the \"SMOOTH\" function or an afiliate"]
@variables Expected_Return_Trend(t)  [description = "Expected_Return_Trend"]
@variables Fact_Prod_Gr_Rt_Decline_Rt(t)  [description = "Fact_Prod_Gr_Rt_Decline_Rt"]
@variables Fact_Prod_Incr_Rt(t)  [description = "Fact_Prod_Incr_Rt"]
@variables Feedback_Cooling(t)  [description = "Feedback_Cooling"]
@variables GHG_Red_Cost_Frac(t)  [description = "GHG_Red_Cost_Frac"]
@variables GHG_Reduction_Frac(t)  [description = "GHG_Reduction_Frac"]
@variables Heat_Transfer(t)  [description = "Heat_Transfer"]
@variables Indicated_Interest_Rate(t)  [description = "Indicated_Interest_Rate"]
@variables Investment(t)  [description = "Investment"]
@variables Investment_Fraction(t)  [description = "Investment_Fraction"]
@variables Labor_Output_Ratio(t)  [description = "Labor_Output_Ratio"]
@variables Marg_Prod_Capital(t)  [description = "Marg_Prod_Capital"]
@variables Marg_Prod_Carbon(t)  [description = "Marg_Prod_Carbon"]
@variables Marg_Return_Capital(t)  [description = "Marg_Return_Capital"]
@variables Net_CC_Impact(t)  [description = "Net_CC_Impact"]
@variables Net_Investment(t)  [description = "Net_Investment"]
@variables Net_Pop_Incr(t)  [description = "Net_Pop_Incr"]
@variables Net_Savings_Rate(t)  [description = "Net_Savings_Rate"]
@variables Output(t)  [description = "Output"]
@variables Pop_Gr_Rt_Decline_Rt(t)  [description = "Pop_Gr_Rt_Decline_Rt"]
@variables Radiative_Forcing(t)  [description = "Radiative_Forcing"]
@variables Rate_of_CO2_Transfer(t)  [description = "Rate_of_CO2_Transfer"]
@variables Reduction_Costs(t)  [description = "Reduction_Costs"]
@variables Reference_CO2_Emissions(t)  [description = "Reference_CO2_Emissions"]
@variables Reference_Output(t)  [description = "Reference_Output"]
@variables TEMPVAR_Smoothed_return(t) = 0.0789017
 #arbitrary value
@variables TEMPVARSMOOTHED_Smoothed_Return(t) = (TEMPVAR_Smoothed_return) [description = "TEMPVARSMOOTHED_Smoothed_Return, created by the \"SMOOTH\" function or an afiliate"]
@variables Smoothed_Return(t)  [description = "Smoothed_Return"]
@variables Temp_Diff(t)  [description = "Temp_Diff"]
@variables Total_Pop_Utility(t)  [description = "Total_Pop_Utility"]
@variables uncontrolled_emissions(t)  [description = "uncontrolled_emissions"]
@variables Utility(t)  [description = "Utility"]


#définition des tables:

Other_GHG_Rad_Forcing_base =Vector{Float64}([0.41,0.5,0.6,0.7,0.78,0.87,0.96,1.05,1.14,1.2,1.25,1.29,1.32,1.35,1.36,])
Other_GHG_Rad_Forcing_ranges = Vector{Float64}([1965.0,1975.0,1985.0,1995.0,2005.0,2015.0,2025.0,2035.0,2045.0,2055.0,2065.0,2075.0,2085.0,2095.0,2105.0,])
Other_GHG_Rad_Forcing(t)=LinearInterpolation(Other_GHG_Rad_Forcing_base,Other_GHG_Rad_Forcing_ranges)(t)
@register_symbolic Other_GHG_Rad_Forcing(t)



#définition des equations:
eqs = [
        D(Atmos_UOcean_Temp) ~ Chg_A_UO_Temp
        D(Capital) ~ Investment-Depreciation
        D(CO2_in_Atmos) ~ CO2_Net_Emiss-CO2_Storage
        D(CO2_Intens_Decline_Rt) ~ -CO2_Intens_Dec_Rt_Decline_Rt
        D(CO2_Intensity_of_Output) ~ -Decline_CO2_Intens
        D(Cum_Disc_Utility) ~ Discounted_Utility
        D(Deep_Ocean_Temp) ~ Chg_DO_Temp
        D(Fact_Prod_Growth_Rt) ~ -Fact_Prod_Gr_Rt_Decline_Rt
        D(Factor_Productivity) ~ Fact_Prod_Incr_Rt
        D(Pop_Growth_Rate) ~ -Decline_Pop_Gr_Rt
        D(Population) ~ Net_Pop_Incr
        Capital_Labor_Ratio ~ (Capital)/(Population)
        Capital_Life ~ (1)/(Depreciation_Rate)
        Capital_Output_Ratio ~ (Capital)/(Output)
        Chg_A_UO_Temp ~ ((Radiative_Forcing)-((Feedback_Cooling)-(Heat_Transfer)))/(A_UO_Heat_Cap)
        Chg_DO_Temp ~ (Heat_Transfer)/(DO_Heat_Cap)
        Climate_Damage_Frac ~ (1)/((1)+((Climate_Damage_Scale)*(((Atmos_UOcean_Temp)/(Reference_Temperature))^(Climate_Damage_Nonlinearity))))
        Climate_Damages ~ (Reference_Output)*((1)-(Climate_Damage_Frac))
        Climate_Feedback_Param ~ (CO2_Rad_Force_Coeff)/(Climate_Sensitivity)
        CO2_Emiss ~ ((1)-(GHG_Reduction_Frac))*((CO2_Intensity_of_Output)*(Output))
        CO2_Intens_Capital ~ (CO2_Emiss)/(Capital)
        CO2_Intens_Dec_Rt_Decline_Rt ~ (CO2_Intens_Decline_Rt)*(Fact_Prod_Gr_Rt_Dec_Rt)
        CO2_Net_Emiss ~ (Atmos_Retention)*(CO2_Emiss)
        CO2_Rad_Forcing ~ 1#(CO2_Rad_Force_Coeff)*(log((2),((CO2_in_Atmos)/(Preindustrial_CO2))))
        Cons_Growth_Rate ~ 1#(log((Consumption_per_Cap)/(TEMPVARSMOOTHED_Cons_Growth_Rate)))/(TIME_STEP)
        Consumption ~ (Output)-(Investment)
        Consumption_per_Cap ~ (Consumption)/(Population)
        Decline_CO2_Intens ~ (CO2_Intensity_of_Output)*(CO2_Intens_Decline_Rt)
        Decline_Pop_Gr_Rt ~ (Pop_Growth_Rate)*(Pop_Gr_Rt_Decline_Rt)
        Depreciation ~ (Capital)*(Depreciation_Rate)
        Desired_Capital_Growth_Rate ~ (((Expected_Return)-(Rate_of_Time_Pref))/(Rate_of_Inequal_Aversion))+(Pop_Growth_Rate)
        Discount_Factor ~ exp((-(Rate_of_Time_Pref))*((t)-(Base_Year)))
        Discounted_Utility ~ (Total_Pop_Utility)*(Discount_Factor)
        DO_Heat_Cap ~ (Heat_Capacity_Ratio)*(Heat_Trans_Coeff)
        Expected_Return ~ (Marg_Return_Capital)+((Expected_Return_Trend)*(Capital_Life))
        Fact_Prod_Gr_Rt_Decline_Rt ~ (Fact_Prod_Growth_Rt)*(Fact_Prod_Gr_Rt_Dec_Rt)
        Fact_Prod_Incr_Rt ~ (Factor_Productivity)*(Fact_Prod_Growth_Rt)
        Feedback_Cooling ~ (Atmos_UOcean_Temp)*(Climate_Feedback_Param)
        GHG_Red_Cost_Frac ~ (1)-((Red_Cost_Scale)*(IfElse.ifelse((GHG_Reduction_Frac)>(0),((GHG_Reduction_Frac)^(Red_Cost_Nonlinearity)),(0))))
        GHG_Reduction_Frac ~ ((IfElse.ifelse( t<(Reduction_Start_Time),0,(1)))*(max((0),(min((1),((constant_reduction)+(((concentration_sensitivity)*(((CO2_in_Atmos)-(Preindustrial_CO2))/(Preindustrial_CO2)))+((emissions_sensitivity)*(((uncontrolled_emissions)-(reference_emissions))/(reference_emissions))))))))))
        Heat_Transfer ~ (Temp_Diff)*((DO_Heat_Cap)/(Heat_Trans_Coeff))
        Indicated_Interest_Rate ~ (Rate_of_Time_Pref)+((Cons_Growth_Rate)*(Rate_of_Inequal_Aversion))
        Investment ~ min((Output),((Depreciation)+((Capital)*(Desired_Capital_Growth_Rate))))
        Investment_Fraction ~ (Investment)/(Output)
        Labor_Output_Ratio ~ (Population)/(Output)
        Marg_Prod_Capital ~ (Capital_Elast_Output)*((Output)/(Capital))
        Marg_Prod_Carbon ~ (Reference_Output)/((Reference_CO2_Emissions)*((Red_Cost_Scale)*((Red_Cost_Nonlinearity)*(IfElse.ifelse((GHG_Reduction_Frac)>(0),((GHG_Reduction_Frac)^((Red_Cost_Nonlinearity)-(1))),(0))))))
        Marg_Return_Capital ~ (Marg_Prod_Capital)-(Depreciation_Rate)
        Net_CC_Impact ~ (GHG_Red_Cost_Frac)*(Climate_Damage_Frac)
        Net_Investment ~ (Investment)-(Depreciation)
        Net_Pop_Incr ~ (Population)*(Pop_Growth_Rate)
        Net_Savings_Rate ~ (Net_Investment)/(Output)
        Output ~ (Reference_Output)*(Net_CC_Impact)
        Pop_Gr_Rt_Decline_Rt ~ (Init_Pop_Growth_Rate)/(log((Ultimate_Population)/(Initial_Population)))
        Radiative_Forcing ~ (CO2_Rad_Forcing)+(Other_GHG_Rad_Forcing(((t)/(one_year))))
        Rate_of_CO2_Transfer ~ (1)/(CO2_Transfer_Time)
        Reduction_Costs ~ ((1)-(GHG_Red_Cost_Frac))*(Reference_Output)
        Reference_CO2_Emissions ~ (Reference_Output)*(CO2_Intensity_of_Output)
        Reference_Output ~ 1#(Output_in_1965)*((Factor_Productivity)*((((Capital)/(Initial_Capital))^(Capital_Elast_Output))*(((Population)/(Initial_Population))^((1)-(Capital_Elast_Output)))))
        Temp_Diff ~ (Atmos_UOcean_Temp)-(Deep_Ocean_Temp)
        Total_Pop_Utility ~ (Utility)*(Population)
        uncontrolled_emissions ~ (Reference_Output)*(CO2_Intensity_of_Output)
        Utility ~ 1#(Utility_Coeff)*(IfElse.ifelse((Rate_of_Inequal_Aversion)==(1),(log((Consumption_per_Cap)/(Ref_Cons_per_Cap))),(((((Consumption_per_Cap)/(Ref_Cons_per_Cap))^((1)-(Rate_of_Inequal_Aversion)))-(1))/((1)-(Rate_of_Inequal_Aversion)))))
        D(TEMPVARSMOOTHED_Expected_Return_Trend) ~ ((((Marg_Return_Capital)-(Smoothed_Return))/(smoothing_time))-TEMPVARSMOOTHED_Expected_Return_Trend) /(smoothing_time)
        Expected_Return_Trend ~ TEMPVARSMOOTHED_Expected_Return_Trend
        D(TEMPVARSMOOTHED_Smoothed_Return) ~ ((Marg_Return_Capital)-TEMPVARSMOOTHED_Smoothed_Return) /(smoothing_time)
        Smoothed_Return ~ TEMPVARSMOOTHED_Smoothed_Return
        CO2_Storage ~ ((CO2_in_Atmos)-(Preindustrial_CO2))*(Rate_of_CO2_Transfer)
        D(TEMPVARSMOOTHED_Cons_Growth_Rate) ~ ((Consumption_per_Cap)-TEMPVARSMOOTHED_Cons_Growth_Rate) /(TIME_STEP)
        TEMPVAR_Smoothed_return ~ (Marg_Return_Capital)-((Initial_Return_Trend)*(smoothing_time))
        TEMPVAR_Expected_Return_Trend ~ Initial_Return_Trend
        TEMPVAR_Cons_Growth_Rate ~ Consumption_per_Cap
        
]

#il faut maintenant définir le solveur:

@named sys= ODESystem(eqs)
sys= structural_simplify(sys)
prob= ODEProblem(sys,[],(1965,2305))
solved=solve(prob)
using Plots

#plot(solved)
