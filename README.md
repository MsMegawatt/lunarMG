# lunarMG

**System Overview**

What is described here is a Simulink simulation of a DC microgrid containing a PV array, MPPT controller, boost converter, buck converter, battery storage, and a variety of loads. The system is currently a single islanded microgrid with conventional device-level droop controls, but future iterations could feature a network of DC microgrids with higher levels of supervisory controls, with an optimal layer and an adaptive layer, as well as predictive, preventative, mitigative, and restorative mechanisms. The current ‘naive’ control regime is meant to display the impact of strictly device-level controls on the DC microgrid under normal operating conditions, load switching, and short circuit conditions. The system was simulated in MATLAB Simulink (version 2022a), which is a platform commonly used in the electrical engineering industry and is currently being used for microgrid simulation at Glenn Research Center. The simulation can be executed by downloading all files on your local machine and running an M-File named “lunar_MG_scenarios.m”, which will run four distinct scenarios that could occur on the moon due to various environmental hazards - including a base scenario, loss of half the PV system, a line-to-line fault at the PV system, and a line-to-line fault at the load side of the system. Each scenario runs with Earth conditions for irradiance and temperature, and then with Lunar conditions, which introduces additional instability into the system. 

**How to Use This Model**
1. Download the entire folder onto your local machine or server.

2. Open the M-File called “lunar_MG_scenarios.m” and either run it to keep the default settings or change the following variables to initialize the model differently:
    -PV_fail - The time at which PV array 2 disconnects from the converters and loads. This is used in the half PV array failure scenario and by default is set to 5 seconds. 
    -load_switch - The time at which the variable resistive load switches on. This is used for all scenarios and introduces load switching into the model to demonstrate effects on stability. The default is 5 seconds and it can be set to any number above 10 seconds if load switching is not desired.

3. The M-file automatically loads temperature and irradiance data from CSV files. There is one CSV file for Earth conditions and three files for Lunar conditions: stable, moderate, and extreme. The extreme Lunar data is used by default but the M-file can be modified to load any of the other Lunar conditions instead.

4. Once the variables and data are as desired, run the M-file. The main window will read out print statements indicating progress. When I run it on my local machine the simulation generally takes about 25 minutes to complete.
The simulation automatically saves the results as .png files in the “plots” folder. At the end, the simulation prints the total elapsed runtime in seconds.

The DC microgrid model is described in detail in the following sections.

**System Components**

**PV Array**

For the PV array, this model uses Simulink’s built-in array block, which is sufficient for the purposes of this simulation. The built-in PV array block adjusts PV array current and voltage according to the inputs of irradiance and temperature, respectively. This block allows the user to select from a variety of panels, including user-defined parameters for atypical panel materials and extreme cell temperatures appropriate for space applications. The built-in PV block allows the user to modify the bandgap of the material, which changes the impact that temperature has on the module saturation current due to the dependence of the intrinsic carrier concentration on bandgap energy and the energy of the carriers themselves. The key equations governing the behavior of a PV cell are presented in [1].

Let us now consider the control of the PV system. Firstly, it is mandatory to perform Maximum Power Point Tracking (MPPT), aiming at maximizing the extracted energy irrespective of the irradiance conditions. This is achieved by the use of a boost converter and MPPT controller using the perturb and observe algorithm. Secondly, the output voltage of the PV system must be also regulated for load feeding considerations. In this model, a buck converter is controlled by a proportional-integral controller to achieve constant output voltage. Two-stage and single-stage single converter topology would be ideal for space applications due to having fewer components and less weight, but I was unable to implement such a controller, so I implemented a two-converter approach that is more common for terrestrial systems. In this model, both converters operate in continuous conduction mode (CCM). Each converter, along with control strategies, is described below.

**Boost Converter**

The boost converter is a DC/DC converter that boosts the voltage close to track the maximum power output of the PV arrays, while stepping down the current. In this system, the boost converter takes in voltage from the PV system at about 300 Vdc, give or take based on temperature changes and solar availability. The voltage is then boosted with a combination of two semiconductors, including a transistor (in this case a MOSFET) and a diode, and energy storage components such as an inductor and capacitor. Boost converters have two switching states, the first of which is when the MOSFET is on and  the second when it is off. In the on state, current flows through the inductor in the clockwise direction and the inductor stores some energy by generating a magnetic field. In the off state, current will be reduced as the impedance is higher. The inductor magnetic field will be reduced to maintain the current towards the load. Thus the voltage polarity will be reversed and as a result, two sources will be in series causing a higher voltage to charge the capacitor through the diode.

The boost converter in this model is designed to use a MOSFET transistor with a switching speed of 5 kHz. To size the boost converter components, the first step is to determine the duty cycle (D) for the minimum input voltage. The minimum input voltage is used because this leads to the maximum switch current (Eq. 1):

D = 1 -(Vin (min))/Vout

= 1 - (275  .9)/500

= .495

The next step is to find the inductor size (Eq. 2):

L = (Vin  (Vout - Vin)) / (IL fs  Vout) 

Where IL is the estimated inductor ripple current. A good estimation for the inductor ripple current is 20% to 40% of the output current (Eq. 3):

IL= (0.2 to 0.4)Iout(max)(Vout/Vin)

For my system, Iout(max) is about 20 A, so:

IL= (0.2 to 0.4)201.818
= 0.336.36
=10.91 A

Going back to Eq. 2:

L = (275  (500 - 275)) / (10.91 5000 500)
= 61875 / 27275000
= 0.002269
= 2.269 e -3

Now to find the output capacitor size:

Cout(min)= (Iout(max) D)/(fsVout)

Where Vout is the expected voltage ripple. Now to calculate the expected output voltage ripple, we use this equation (Eq. 4):
Vout= ESR((Iout(max)/(1-D))+ IL/2)
=0.1  (20/.505 + 10.91/2)
= 4.506 V

To complete the calculation:

Cout(min)= (20  .495)/(5000  4.506)
= 0.0004394
=4.394 e -4

**Maximum Power Point Tracking (MPPT) Controller**

The output voltage and current of a PV array are related by an “I-V curve”, the shape of which is dependent on the irradiance incident on the panel surface and the ambient (cell) temperature. This can also be referred to as the “I-V characteristics”.  The point at which the array produces maximum output power - or the maximum power point (MPP) - is the “knee” of this curve, where the integral under the curve, essentially I*V, is the greatest. 

To maximize the power produced by a PV system, the MPP should be tracked continuously by a MPPT algorithm. Some widely used algorithms include ‘incremental conductance’ and ‘perturb and observe’, the latter of which is used in this model because it presents a decent compromise between simplicity and accuracy. The algorithm typically operates by taking in the array voltage, current, and a number of user-generated parameters and using those inputs to generate a duty cycle. The duty cycle from the MPPT creates switching signals for the boost converter and allows the boost converter to operate the solar PV system at optimum voltage and current so that the maximum power extraction is possible. 

The MPPT control function for this model takes in user-defined parameters (Param), an on/off signal (Enabled), and the PV array voltage (V) and current (I) at timestep t. The parameters include an initial duty cycle, maximum and minimum duty cycle, and increment by which the duty cycle is perturbed between timesteps. Enabled is set at a constant of 1, which means it is always on. The control function logic dictates that the duty cycle is changed only for non-zero changes in power when the MPPT controller is enabled. If the change in power and voltage are both negative from the previous timestep, then duty cycle D decreases by the user-determined increment ‘deltaD’. If power decreased but voltage increased from the previous timestep, then D increases by deltaD. If power increased but voltage decreased, D increases and if power increased and voltage increased then D decreases. Basically if the change in power and voltage are both positive or negative, D goes down, and if their changes differ in sign then D goes up.

**Buck Converter**

The buck converter is a DC/DC converter that decreases the transmission voltage to a set range of 280-300V to meet the required voltage at the system loads. In this system, the buck converter takes in voltage from the boost converter at about 500 Vdc and reduces it to somewhere within the desired range. Like the boost converter, the buck converter also contains two semiconductors, including a transistor (in this case a MOSFET) and a diode, and energy storage components such as an inductor and capacitor. Buck converters have two switching states, the first of which is when the MOSFET is on and the second when it is off. Beginning with the switch open (off-state), the current in the circuit is zero. When the switch is first closed (on-state), the current will begin to increase, and the inductor will produce an opposing voltage across its terminals in response to the changing current. This voltage drop counteracts the voltage of the source and therefore reduces the net voltage across the load. Over time, the rate of change of current decreases, and the voltage across the inductor also decreases, increasing the voltage at the load. During this time, the inductor stores energy in the form of a magnetic field.

If the switch is opened while the current is still changing, then there will always be a voltage drop across the inductor, so the net voltage at the load will always be less than the input voltage source. When the switch is opened again (off-state), the voltage source will be removed from the circuit, and the current will decrease. The decreasing current will produce a voltage drop across the inductor (opposite to the drop at on-state), and now the inductor becomes a current source. The stored energy in the inductor's magnetic field supports the current flow through the load. This current, flowing while the input voltage source is disconnected, when appended to the current flowing during on-state, totals to current greater than the average input current (being zero during off-state).

The buck converter in this model is designed to use a MOSFET transistor with WBG semiconducting materials, so the switching frequency is set at 10 MHz. To size the converter components, the first step is to determine the duty cycle (D) for the minimum input voltage. The minimum input voltage is used because this leads to the maximum switch current (Eq. 5):

D = Vout/(Vin)

= 300/(5000.9)

= .667

Next, find the inductor size (Eq. 6):

L = (Vout  (Vin - Vout)) / (IL fs  Vin) 

Where IL is the estimated inductor ripple current. A good estimation for the inductor ripple current is 20% to 40% of the output current (Eq. 7):

IL= (0.2 to 0.4)Iout(max)

For my system, Iout(max) is about 20 A, so:

IL= (0.2 to 0.4)20
= 0.320
=6 A

Going back to Eq. 6:

L = (300  (500 - 300)) / (6 1000 500)
= 60000 / 3000000
= 0.02
= 20 e -3

Now to find the output capacitor size:

Cout(min)=IL/(8  fsVout)

Where Vout is the expected voltage ripple. Now to calculate the expected output voltage ripple, we use this equation (Eq. 8):
Vout= ESRIL
=0.1 6
= 0.6 V  

To complete the calculation:

Cout(min)= 6 / (8 10000.6)
= 0.000125
=1.25 e -4

**PI Controller**

The buck converter is controlled by a proportional integral (PI) controller, which determines the duty cycle of the buck converter, which in turn sets the output voltage at the desired level (Vref). In this case, Vref is set to 300 V. The proportional and integral gains were both set to 1 initially and then were tuned to adequately supply 300V to the DC bus over a range of normal operating conditions and loads. The PI controller was tuned by first modulating the proportional gain until the duty cycle spanned a reasonable magnitude, and then once this was achieved the integral gain was modulated until the duty cycle remained relatively constant during the course of the simulation. A more scientific approach to PI controller tuning would be one improvement that could be made to this model.

**A Note on Converters for Space Applications**

The primary form of electricity in space is direct current (DC), which will likely still be the case for the near future until nuclear fission reactors can safely be transported to the Lunar surface. DC/DC converters are a key element of DC electrical systems because they increase or decrease the voltage to meet the requirements at a particular bus. NASA’s current expectation is that Lunar power system voltage levels will be about 28-120 V at the distribution level and 600-1000V at the transmission level [2]. While higher voltages mean lower current and thereby lower line losses, higher DC voltages also mean more robust and complex protection mechanisms.

DC/DC converters contain semiconducting materials. Typical converters use narrow bandgap semiconductor materials such as silicon, which has a bandgap of about 1-1.5 eV. Semiconductors for space applications, on the other hand, use wide bandgap (WBG) semiconductors that have bandgaps of about 2 eV or more. WBG semiconductors are one of the leading contenders for next-generation devices for general semiconductor use because they permit devices to operate at much higher voltages, frequencies, and temperatures than conventional semiconductor materials. They can also operate at higher currents due to their higher inherent critical field densities, so their use enables higher power density. Materials that fall in this category include Gallium Nitride (GaN), Copper Oxide (Cu2O), and Zinc Telluride (ZnTe). WBG semiconductors can operate at higher switching frequencies, which leads to a higher operating efficiency. Faster switching speed also enables faster converter controls, which tend to have time constants of about 10x slower than the converter switching speed. For example, a boost converter with 1 MHz switching speed might be controlled by a PI controller that operates at 100 kHz. For the purposes of this simulation, the switching speed is not of great importance, so converters in this model are set to switch at 1 kHz for the purpose of computational speed.

**Storage**

The energy storage block of this model includes 96 kWhs of battery storage, which is controlled by two converters - a buck converter for charging and a boost converter for discharging - both of which are controlled by two PI controllers. The PI controllers were tuned similarly to the one controlling the buck converter in the PV block.

MORE ON THIS SECTION TBD


**References**

[1] Nguyen, X.H., Nguyen, M.P. Mathematical modeling of photovoltaic cell/module/arrays with tags in Matlab/Simulink. Environ Syst Res 4, 24 (2015). https://doi.org/10.1186/s40068-015-0047-9

[2] Glenn Research Center presentation.
