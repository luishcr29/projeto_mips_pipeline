-- FPAdd corrigido - SEM declarações de componentes internos
-- Os componentes auxiliares são entidades separadas no projeto
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library std;
use std.textio.all;
library work;

--------------------------------------------------------------------------------
entity FPAdd_8_23_comb_uid2 is
    port (X : in  std_logic_vector(8+23+2 downto 0);
          Y : in  std_logic_vector(8+23+2 downto 0);
          R : out  std_logic_vector(8+23+2 downto 0)   );
end entity;

architecture arch of FPAdd_8_23_comb_uid2 is
   -- Declarações de componentes (referências às entidades já existentes)
   component IntDualSub_26_comb_uid4 is
      port ( X : in  std_logic_vector(25 downto 0);
             Y : in  std_logic_vector(25 downto 0);
             XmY : out  std_logic_vector(25 downto 0);
             YmX : out  std_logic_vector(25 downto 0)   );
   end component;

   component Normalizer_Z_25_25_25_comb_uid6 is
      port ( X : in  std_logic_vector(24 downto 0);
             Count : out  std_logic_vector(4 downto 0);
             R : out  std_logic_vector(24 downto 0)   );
   end component;

   component RightShifterSticky24_by_max_26_comb_uid8 is
      port ( X : in  std_logic_vector(23 downto 0);
             S : in  std_logic_vector(4 downto 0);
             R : out  std_logic_vector(25 downto 0);
             Sticky : out  std_logic   );
   end component;

   component IntAdder_27_comb_uid10 is
      port ( X : in  std_logic_vector(26 downto 0);
             Y : in  std_logic_vector(26 downto 0);
             Cin : in  std_logic;
             R : out  std_logic_vector(26 downto 0)   );
   end component;

   component IntAdder_33_comb_uid13 is
      port ( X : in  std_logic_vector(32 downto 0);
             Y : in  std_logic_vector(32 downto 0);
             Cin : in  std_logic;
             R : out  std_logic_vector(32 downto 0)   );
   end component;

signal inX, inY :  std_logic_vector(33 downto 0);
signal exceptionXSuperiorY, exceptionXEqualY :  std_logic;
signal signedExponentX, signedExponentY, exponentDifferenceXY :  std_logic_vector(8 downto 0);
signal exponentDifferenceYX :  std_logic_vector(7 downto 0);
signal swap :  std_logic;
signal newX, newY :  std_logic_vector(33 downto 0);
signal exponentDifference :  std_logic_vector(7 downto 0);
signal shiftedOut :  std_logic;
signal shiftVal :  std_logic_vector(4 downto 0);
signal EffSub, selectClosePath :  std_logic;
signal sdExnXY :  std_logic_vector(3 downto 0);
signal pipeSignY :  std_logic;
signal fracXClose1, fracYClose1, fracRClosexMy, fracRCloseyMx :  std_logic_vector(25 downto 0);
signal fracSignClose :  std_logic;
signal fracRClose1 :  std_logic_vector(24 downto 0);
signal resSign :  std_logic;
signal nZerosNew :  std_logic_vector(4 downto 0);
signal shiftedFrac :  std_logic_vector(24 downto 0);
signal roundClose0, resultCloseIsZero0 :  std_logic;
signal exponentResultClose :  std_logic_vector(9 downto 0);
signal resultBeforeRoundClose :  std_logic_vector(32 downto 0);
signal roundClose, resultCloseIsZero :  std_logic;
signal fracNewY :  std_logic_vector(23 downto 0);
signal shiftedFracY :  std_logic_vector(25 downto 0);
signal sticky :  std_logic;
signal fracYfar :  std_logic_vector(26 downto 0);
signal EffSubVector, fracYfarXorOp, fracXfar :  std_logic_vector(26 downto 0);
signal cInAddFar :  std_logic;
signal fracResultfar0, fracResultFarNormStage :  std_logic_vector(26 downto 0);
signal fracLeadingBits :  std_logic_vector(1 downto 0);
signal fracResultFar1 :  std_logic_vector(22 downto 0);
signal fracResultRoundBit, fracResultStickyBit, roundFar1 :  std_logic;
signal expOperationSel :  std_logic_vector(1 downto 0);
signal exponentUpdate, exponentResultfar0, exponentResultFar1 :  std_logic_vector(9 downto 0);
signal resultBeforeRoundFar :  std_logic_vector(32 downto 0);
signal roundFar :  std_logic;
signal resultBeforeRound :  std_logic_vector(32 downto 0);
signal round, zeroFromClose :  std_logic;
signal resultRounded :  std_logic_vector(32 downto 0);
signal syncEffSub :  std_logic;
signal syncX :  std_logic_vector(33 downto 0);
signal syncSignY, syncResSign :  std_logic;
signal UnderflowOverflow :  std_logic_vector(1 downto 0);
signal resultNoExn :  std_logic_vector(33 downto 0);
signal syncExnXY :  std_logic_vector(3 downto 0);
signal exnR :  std_logic_vector(1 downto 0);
signal sgnR :  std_logic;
signal expsigR :  std_logic_vector(30 downto 0);
begin
   inX <= X;
   inY <= Y;
   exceptionXSuperiorY <= '1' when unsigned(inX(33 downto 32)) >= unsigned(inY(33 downto 32)) else '0';
   exceptionXEqualY <= '1' when inX(33 downto 32) = inY(33 downto 32) else '0';
   signedExponentX <= "0" & inX(30 downto 23);
   signedExponentY <= "0" & inY(30 downto 23);
   exponentDifferenceXY <= std_logic_vector(unsigned(signedExponentX) - unsigned(signedExponentY));
   exponentDifferenceYX <= std_logic_vector(unsigned(signedExponentY(7 downto 0)) - unsigned(signedExponentX(7 downto 0)));
   swap <= (exceptionXEqualY and exponentDifferenceXY(8)) or (not(exceptionXSuperiorY));
   newX <= inY when swap = '1' else inX;
   newY <= inX when swap = '1' else inY;
   exponentDifference <= exponentDifferenceYX when swap = '1' else exponentDifferenceXY(7 downto 0);
   shiftedOut <= exponentDifference(7) or exponentDifference(6) or exponentDifference(5);
   shiftVal <= exponentDifference(4 downto 0) when shiftedOut='0' else std_logic_vector(to_unsigned(26,5));
   EffSub <= newX(31) xor newY(31);
   selectClosePath <= EffSub when exponentDifference(7 downto 1) = (7 downto 1 => '0') else '0';
   sdExnXY <= newX(33 downto 32) & newY(33 downto 32);
   pipeSignY <= newY(31);

   fracXClose1 <= "01" & newX(22 downto 0) & '0';
   with exponentDifference(0)  select 
   fracYClose1 <=  "01" & newY(22 downto 0) & '0' when '0',
                  "001" & newY(22 downto 0)       when others;
   FPAdd_8_23_comb_uid2_DualSubClose: IntDualSub_26_comb_uid4
      port map ( X => fracXClose1, Y => fracYClose1, XmY => fracRClosexMy, YmX => fracRCloseyMx);
   fracSignClose <= fracRClosexMy(25);
   fracRClose1 <= fracRClosexMy(24 downto 0) when fracSignClose='0' else fracRCloseyMx(24 downto 0);
   resSign <= '0' when selectClosePath='1' and fracRClose1 = (24 downto 0 => '0') else
             newX(31) xor (selectClosePath and fracSignClose);
   norm: Normalizer_Z_25_25_25_comb_uid6
      port map ( X => fracRClose1, Count => nZerosNew, R => shiftedFrac);
   roundClose0 <= shiftedFrac(0) and shiftedFrac(1);
   resultCloseIsZero0 <= '1' when nZerosNew = std_logic_vector(to_unsigned(31, 5)) else '0';
   exponentResultClose <= std_logic_vector(unsigned("00" & newX(30 downto 23)) - (unsigned("00000" & nZerosNew)));
   resultBeforeRoundClose <= exponentResultClose(9 downto 0) & shiftedFrac(23 downto 1);
   roundClose <= roundClose0;
   resultCloseIsZero <= resultCloseIsZero0;

   fracNewY <= '1' & newY(22 downto 0);
   RightShifterComponent: RightShifterSticky24_by_max_26_comb_uid8
      port map ( S => shiftVal, X => fracNewY, R => shiftedFracY, Sticky => sticky);
   fracYfar <= "0" & shiftedFracY;
   EffSubVector <= (26 downto 0 => EffSub);
   fracYfarXorOp <= fracYfar xor EffSubVector;
   fracXfar <= "01" & (newX(22 downto 0)) & "00";
   cInAddFar <= EffSub and not sticky;
   FPAdd_8_23_comb_uid2_fracAddFar: IntAdder_27_comb_uid10
      port map ( Cin => cInAddFar, X => fracXfar, Y => fracYfarXorOp, R => fracResultfar0);
   fracResultFarNormStage <= fracResultfar0;
   fracLeadingBits <= fracResultFarNormStage(26 downto 25) ;
   fracResultFar1 <=
           fracResultFarNormStage(23 downto 1)  when fracLeadingBits = "00" 
      else fracResultFarNormStage(24 downto 2)  when fracLeadingBits = "01" 
      else fracResultFarNormStage(25 downto 3);
   fracResultRoundBit <=
           fracResultFarNormStage(0) when fracLeadingBits = "00" 
      else fracResultFarNormStage(1)    when fracLeadingBits = "01" 
      else fracResultFarNormStage(2) ;
   fracResultStickyBit <=
           sticky when fracLeadingBits = "00" 
      else fracResultFarNormStage(0) or  sticky   when fracLeadingBits = "01" 
      else fracResultFarNormStage(1) or fracResultFarNormStage(0) or sticky;
   roundFar1 <= fracResultRoundBit and (fracResultStickyBit or fracResultFar1(0));
   expOperationSel <= "11" when fracLeadingBits = "00" else "00" when fracLeadingBits = "01" else "01";
   exponentUpdate <= (9 downto 1 => expOperationSel(1)) & expOperationSel(0);
   exponentResultfar0<="00" & (newX(30 downto 23));
   exponentResultFar1 <= std_logic_vector(unsigned(exponentResultfar0) + unsigned(exponentUpdate));
   resultBeforeRoundFar <= exponentResultFar1 & fracResultFar1;
   roundFar <= roundFar1;

   with selectClosePath  select 
   resultBeforeRound <= resultBeforeRoundClose when '1', resultBeforeRoundFar   when others;
   with selectClosePath  select 
   round <= roundClose when '1', roundFar   when others;
   zeroFromClose <= selectClosePath and resultCloseIsZero;

   FPAdd_8_23_comb_uid2_finalRoundAdd: IntAdder_33_comb_uid13
      port map ( Cin => round, X => resultBeforeRound, Y => "000000000000000000000000000000000", R => resultRounded);
   syncEffSub <= EffSub;
   syncX <= newX;
   syncSignY <= pipeSignY;
   syncResSign <= resSign;
   UnderflowOverflow <= resultRounded(32 downto 31);
   with UnderflowOverflow  select 
   resultNoExn(33 downto 32) <=   (not zeroFromClose) & "0" when "01",
                                 "00" when "10" | "11",
                                 "0" &  not zeroFromClose  when others;
   resultNoExn(31 downto 0) <= syncResSign & resultRounded(30 downto 0);
   syncExnXY <= sdExnXY;
   with syncExnXY  select 
      exnR <= resultNoExn(33 downto 32) when "0101",
              "1" & syncEffSub          when "1010",
              "11"                      when "1110",
              syncExnXY(3 downto 2)     when others;
   with syncExnXY  select 
      sgnR <= resultNoExn(31)         when "0101",
              syncX(31) and syncSignY when "0000",
              syncX(31)               when others;
   with syncExnXY  select   
      expsigR <= resultNoExn(30 downto 0)   when "0101" ,
                 syncX(30 downto  0)        when others;
   R <= exnR & sgnR & expsigR;
end architecture;