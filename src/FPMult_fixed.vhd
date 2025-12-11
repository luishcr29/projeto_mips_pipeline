-- FPMult corrigido - SEM declarações de componentes internos
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library std;
use std.textio.all;
library work;

entity FPMult_8_23_uid2_comb_uid3 is
    port (X : in  std_logic_vector(8+23+2 downto 0);
          Y : in  std_logic_vector(8+23+2 downto 0);
          R : out  std_logic_vector(8+23+2 downto 0)   );
end entity;

architecture arch of FPMult_8_23_uid2_comb_uid3 is
   component IntMultiplier_24x24_48_comb_uid5 is
      port ( X : in  std_logic_vector(23 downto 0);
             Y : in  std_logic_vector(23 downto 0);
             R : out  std_logic_vector(47 downto 0)   );
   end component;

   component IntAdder_33_comb_uid9 is
      port ( X : in  std_logic_vector(32 downto 0);
             Y : in  std_logic_vector(32 downto 0);
             Cin : in  std_logic;
             R : out  std_logic_vector(32 downto 0)   );
   end component;

signal sign :  std_logic;
signal expX, expY :  std_logic_vector(7 downto 0);
signal expSumPreSub :  std_logic_vector(9 downto 0);
signal bias :  std_logic_vector(9 downto 0);
signal expSum :  std_logic_vector(9 downto 0);
signal sigX, sigY :  std_logic_vector(23 downto 0);
signal sigProd :  std_logic_vector(47 downto 0);
signal excSel :  std_logic_vector(3 downto 0);
signal exc :  std_logic_vector(1 downto 0);
signal norm :  std_logic;
signal expPostNorm :  std_logic_vector(9 downto 0);
signal sigProdExt :  std_logic_vector(47 downto 0);
signal expSig :  std_logic_vector(32 downto 0);
signal sticky, guard :  std_logic;
signal round :  std_logic;
signal expSigPostRound :  std_logic_vector(32 downto 0);
signal excPostNorm :  std_logic_vector(1 downto 0);
signal finalExc :  std_logic_vector(1 downto 0);
begin
   sign <= X(31) xor Y(31);
   expX <= X(30 downto 23);
   expY <= Y(30 downto 23);
   expSumPreSub <= std_logic_vector(unsigned("00" & expX) + unsigned("00" & expY));
   bias <= std_logic_vector(to_unsigned(127,10));
   expSum <= std_logic_vector(unsigned(expSumPreSub) - unsigned(bias));
   sigX <= "1" & X(22 downto 0);
   sigY <= "1" & Y(22 downto 0);
   
   SignificandMultiplication: IntMultiplier_24x24_48_comb_uid5
      port map ( X => sigX, Y => sigY, R => sigProd);
   
   excSel <= X(33 downto 32) & Y(33 downto 32);
   with excSel  select  
   exc <= "00" when  "0000" | "0001" | "0100", 
          "01" when "0101",
          "10" when "0110" | "1001" | "1010" ,
          "11" when others;
   
   norm <= sigProd(47);
   expPostNorm <= std_logic_vector(unsigned(expSum) + ("000000000" & norm));
   sigProdExt <= sigProd(46 downto 0) & "0" when norm='1' else
                 sigProd(45 downto 0) & "00";
   expSig <= expPostNorm & sigProdExt(47 downto 25);
   sticky <= sigProdExt(24);
   guard <= '0' when sigProdExt(23 downto 0)="000000000000000000000000" else '1';
   round <= sticky and ( (guard and not(sigProdExt(25))) or (sigProdExt(25)) );
   
   RoundingAdder: IntAdder_33_comb_uid9
      port map ( Cin => round, X => expSig, Y => "000000000000000000000000000000000", R => expSigPostRound);
   
   with expSigPostRound(32 downto 31)  select 
   excPostNorm <=  "01"  when  "00",
                   "10"  when "01", 
                   "00"  when "11"|"10",
                   "11"  when others;
   
   with exc  select  
   finalExc <= exc when  "11"|"10"|"00",
               excPostNorm when others; 
   
   R <= finalExc & sign & expSigPostRound(30 downto 0);
end architecture;