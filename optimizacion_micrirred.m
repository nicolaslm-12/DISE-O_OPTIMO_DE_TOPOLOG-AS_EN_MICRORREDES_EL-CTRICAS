clc
%%%% COSTO CARGAS Y CON/TRAS %%%
sistema_PV= 15066324;
diesel_kWh = 291;
kWh = 582;
convertidor_PV = 5000000;
generador_D = 5846900;
trasfo = 8000000;
convertidor_nevera =109600;
convertidor_luz = 109600;

load('consumo_laboral_cargas.mat')
load('consumo_nolaboral_cargas.mat')
load('consumo_dia_laboral_in_aire.mat')
load('consumo_dia_no_laboral_in_aire.mat')
load('consumo_dia_laboral_ve_aire.mat')
load('consumo_dia_no_laboral_ve_aire.mat')
load('perdidas_laboral.mat')
load('perdidas_nolaboral.mat')
load('produccion_pv_invierno.mat')
load('produccion_pv_verano.mat')

%%%%%%%%%%FUNCION OBJETIVO %%%%%%%%%%
MG1=optimproblem('Description','microrred','ObjectiveSense','min');
% DG=optimvar('DG',1);
% Cinv=(sistema_PV+generador_D+convertidor_PV+convertidor_nevera+convertidor_luz+trasfo);
% Cop= kWh*(consumo_anual_cargas(1,1)+consumo_anual_aire(1,1)+perdidas_anual(1,1)-produccion_pv_anual(1,1)*x_generador_pv_IN(1,1)-DG)+diesel_kWh*(DG);
% Pred=(consumo_anual_cargas(1,1)+consumo_anual_aire(1,1)+perdidas_anual(1,1)-produccion_pv_anual(1,1)*x_generador_pv_IN-DG);
% MG1.Objective = Cinv + Cop;
% MG1.Constraints.C1=Pred>=0;
% MG1.Constraints.C2=DG>=0;
% MG1.Constraints.C3=DG<=26000;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DG=optimvar('DG',8736);   
XK = optimvar('XK', 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);
% for i = 1:8736-10 % Iterar hasta 10 horas antes del final
%     MG1.Constraints.(['C4_' num2str(i)]) = sum(DG(i:i+9)) <= 10; % Sumar 10 horas a partir de i
% end

% Definir la variable binaria para controlar el estado de activación de DG
IsDGActive = optimvar('IsDGActive', 8736, 'Type', 'integer', 'LowerBound', 0, 'UpperBound', 1);

% Restricción para asegurar que DG solo puede ser mayor que 0 si IsDGActive es 1
for i = 1:8736
    MG1.Constraints.(['C9_' num2str(i)]) = DG(i) <= IsDGActive(i);
end

% Restricción para asegurar que haya exactamente dos horas activas seguidas seguidas de dos horas inactivas
for i = 1:8736-3
    MG1.Constraints.(['C10_' num2str(i)]) = sum(IsDGActive(i:i+3)) == 2;
end
Cinv=(sistema_PV+generador_D+convertidor_PV+convertidor_nevera+convertidor_luz+trasfo);
Cop=0;
Cop1=0;

DG_Count=0;
for i=1:24
    dia_laboral_in = ((sumatoria_total_dia_laboral(i)+x_aire_lab_in(i)+suma_total_perdidas_dialab(i)-(x_generacion_pv_IN(i)*XK)-DG(i))*107);
    % dia_no_lab_invierno = ((sumatoria_total_dia_no_laboral(i)+y_aire_no_lab_in(i)+suma_total_perdidas_dia_nolab(i)-(x_generacion_pv_IN(i)*XK)-DG(i))*75);
    % dia_laboral_ve = ((sumatoria_total_dia_laboral(i)+w_aire_no_lab_ve(i)+suma_total_perdidas_dialab(i)-(y_generacion_pv_VE(i)*XK)-DG(i))*107);
    % dia_no_lab_verano = ((sumatoria_total_dia_no_laboral(i)+w_aire_no_lab_ve(i)+suma_total_perdidas_dia_nolab(i)-(y_generacion_pv_VE(i)*XK)-DG(i))*75);
   
    Pred=dia_laboral_in+dia_no_lab_invierno+dia_laboral_ve+dia_no_lab_verano;
   
    Cop1=Cop1+ kWh *Pred + diesel_kWh *DG(i);
  
end
MG1.Objective = Cinv + Cop1;
%%%%interconectado%%%%%%%%%%%%%%%%%
MG1.Constraints.C1=Pred>=0;
MG1.Constraints.C2=DG>=0;
MG1.Constraints.C3=DG<=26000;
%%%%%%%%%%aislado%%%%%%%%%%%%%%%%%%%%%
% MG1.Constraints.C1= diesel_kWh==kWh;
% MG1.Constraints.C2=DG>=1300;
% MG1.Constraints.C3=DG<=26000;
% MG1.Constraints.C4=produccion_pv_anual+DG-perdidas_anual-consumo_anual_aire-consumo_anual_cargas==0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[sol0,fval0, exitflag0, output0, lambda0]=solve(MG1);
sol0.DG
sol0.XK
fval0