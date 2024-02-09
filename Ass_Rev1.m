clear;

metoData = readtable("metro_Denmark.csv");

Heat = metoData(:,["Y" "M" "D" "H" "T2m"]);

HouseArea = 225;
WindowsSArea = 36;

H_old = 440;
H_new = 160;
T_internal = 22; 
SHGC = 0.25; 

Q_extra = 611.67; %[W]
Q_losses_old = H_old*(metoData.T2m - T_internal); 
Q_solar = WindowsSArea*SHGC*metoData.G_i_; 
Q_gain = Q_solar + Q_extra;
Heat.Q_old = Q_gain + Q_losses_old;

Q_losses_new = H_new*(metoData.T2m - T_internal);
Heat.Q_net_new = Q_gain + Q_losses_new;

Q_demand_old = min(Q_losses_old + Q_gain, 0); %[W}
Q_demand_old(metoData.T2m > 15) = 0; 
Heat.Q_Demand_old = Q_demand_old;
Total_Q_demand_old = sum(Q_demand_old)/10^3; %[kW] 

Q_demand_new = min(Q_losses_new + Q_gain, 0); %[W}
Q_demand_new(metoData.T2m > 15) = 0; 
Heat.Q_Demand_new = Q_demand_new;
Total_Q_demand_new = sum(Q_demand_new)/10^3; %[kW] 

HeatingRatio_old = Total_Q_demand_old/HouseArea;
HeatingRatio_new = Total_Q_demand_new/HouseArea;
fprintf("Heating Ratio old is %d \n", HeatingRatio_old);
fprintf("Heating Ratio new is %d \n", HeatingRatio_new);

% Heat source Before modernization - Gas boiler

Eff_GasBoiler = 0.95;
Q_GB = Q_demand_old / 0.95; %[W]
Total_Q_GB = sum(Q_GB);
ConversionRatio = 10.55; % 1m^3 = 10.55kWh for natural gas
GasUsage = abs(Total_Q_demand_old/Eff_GasBoiler/ConversionRatio); %[m^3] 

% Heat source After modernization - Heat Pump

COP = [4.17, 3.26, 2.54, 4.81, 3.7, 2.85, 5.59, 4.23, 3.26]';
Power = [2.16, 2.61, 3.28, 2.16, 2.67, 3.32, 2.13, 2.68, 3.32]';
T = [-5, 35; -5, 45; -5, 55; 0, 35; 0, 45; 0, 55; 5, 35; 5, 45; 5, 55;];

heatPump = HPfinal(COP,Power,T);

[Q_HP, Power_HP, COP_cal] = heatPump.calculateHeat(35,metoData.T2m);

Total_Power_HP = sum(Power_HP); %[kW]
Total_Q_HP = sum(Q_HP); %[kW]

figure
plot (abs(Q_demand_old)/10^3, 'DisplayName', 'Q demand old');
hold on
plot (abs(Q_GB)/10^3, 'DisplayName', 'Q supply');
xlabel('Time');
ylabel('Power demand and supply');
title('Comparison of Power demand (old) and supply (kW)');
legend('show');

figure
plot (abs(Q_demand_new)/10^3, 'DisplayName', 'Q demand new');
hold on
plot (abs(Q_HP), 'DisplayName', 'Q supply');
xlabel('Time');
ylabel('Power demand and supply');
title('Comparison of Power demand (new) and supply (kW)');
legend('show');

%% Renewable source

Turbine1 = windTurbine(3.2, 11, 25, 3.5); %[kW]

N_Turbines = 1; 

metoData = readtable("metro_Denmark.csv");

RESSources = metoData(:,["Y" "M" "D" "H"]);

RESSources.Turbine = N_Turbines*Turbine1.calculatePower(metoData.WS10m); %[kW]

ElectricalPower = metoData(:,["Y" "M" "D" "H" "ElectricPower_kW_"]); %[kW]
E_demand_withoutHP = ElectricalPower.ElectricPower_kW_; %[kW]
E_demand_withHP = E_demand_withoutHP + abs(Power_HP);

RESSources.NettGeneration =  RESSources.Turbine - E_demand_withHP;

for hourIterator = 1:height(RESSources) 
    if RESSources.NettGeneration(hourIterator) < 0 
        RESSources.FromGrid(hourIterator) = RESSources.NettGeneration(hourIterator);
        RESSources.ToGrid(hourIterator) = 0;
    else
        RESSources.FromGrid(hourIterator) = 0; 
        RESSources.ToGrid(hourIterator) = RESSources.NettGeneration(hourIterator);
    end
end

Summary_E = table();
Summary_E.E_demand = sum(E_demand_withHP)/10^3;
Summary_E.Turbine = sum(RESSources.Turbine)/10^3;
Summary_E.FromGrid = abs(sum(RESSources.FromGrid))/10^3;
Summary_E.ToGrid = abs(sum(RESSources.ToGrid)/10^3);

figure 
bar(Summary_E{1,:})
ylabel("Energy (MWh)")
xticklabels(Summary_E.Properties.VariableNames)
title('Summary of Energy from renewable resource (MWh)');

figure
plot (E_demand_withHP);
title('Total electricity demand range in different priod of time (kW)');

%% Investment

Invest_Turbine = 10115 * N_Turbines; %dollar
Invest_HP = 5500;

TotalInvest = Invest_HP + Invest_Turbine;

PriceDemand_Elec = 0.42;
PriceDemand_Gas = 2.1;
PriceSupply_Elec = 0.9; 

Cost_Elec_Before = sum(E_demand_withoutHP)*PriceDemand_Elec;
Cost_Elec_After = sum(RESSources.FromGrid)*PriceDemand_Elec;

Saving_Elec = Cost_Elec_Before - Cost_Elec_After;
Saving_Gas = GasUsage*PriceDemand_Gas;

Sell_Elec = sum(RESSources.ToGrid)*PriceSupply_Elec;

NetGain = Saving_Gas + Saving_Elec + Sell_Elec;

PayBackPeriod = TotalInvest/NetGain;
if PayBackPeriod <1
    PayBackPeriod = 1;   
else 
    PayBackPeriod = ceil(PayBackPeriod);
end

fprintf("Pay-back Period, %d years\n", PayBackPeriod);

Summary_I = table();
Summary_I.TotalInvest = TotalInvest;
Summary_I.Saving_Elec = Saving_Elec;
Summary_I.Saving_Gas = Saving_Gas;
Summary_I.Sell_Elec = Sell_Elec;
Summary_I.NetGain = NetGain;

figure 
bar(Summary_I{1,:})
ylabel("Investment (dollars)")
xticklabels(Summary_I.Properties.VariableNames)
title('Investment Summary ($)');
