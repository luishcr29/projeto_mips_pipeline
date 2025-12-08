-- ============================================================================
-- TODOS OS COMPONENTES AUXILIARES FloPoCo EM UM ÚNICO ARQUIVO
-- Para facilitar o uso no EDA Playground
-- VERSÃO CORRIGIDA - Bibliotecas antes de cada entidade
-- ============================================================================

-- ============================================================================
-- 1. IntDualSub_26_comb_uid4
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IntDualSub_26_comb_uid4 is
    port (
        X : in  std_logic_vector(25 downto 0);
        Y : in  std_logic_vector(25 downto 0);
        XmY : out std_logic_vector(25 downto 0);
        YmX : out std_logic_vector(25 downto 0)
    );
end entity;

architecture arch of IntDualSub_26_comb_uid4 is
begin
    XmY <= std_logic_vector(unsigned(X) - unsigned(Y));
    YmX <= std_logic_vector(unsigned(Y) - unsigned(X));
end architecture;

-- ============================================================================
-- 2. Normalizer_Z_25_25_25_comb_uid6
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Normalizer_Z_25_25_25_comb_uid6 is
    port (
        X : in  std_logic_vector(24 downto 0);
        Count : out std_logic_vector(4 downto 0);
        R : out std_logic_vector(24 downto 0)
    );
end entity;

architecture arch of Normalizer_Z_25_25_25_comb_uid6 is
begin
    process(X)
        variable temp : std_logic_vector(24 downto 0);
        variable cnt : integer range 0 to 31;
    begin
        temp := X;
        cnt := 0;
        
        for i in 24 downto 0 loop
            if temp(i) = '1' then
                exit;
            else
                cnt := cnt + 1;
            end if;
        end loop;
        
        if temp = (24 downto 0 => '0') then
            cnt := 31;
        end if;
        
        Count <= std_logic_vector(to_unsigned(cnt, 5));
        
        if cnt < 25 then
            R <= std_logic_vector(shift_left(unsigned(X), cnt));
        else
            R <= (others => '0');
        end if;
    end process;
end architecture;

-- ============================================================================
-- 3. RightShifterSticky24_by_max_26_comb_uid8
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RightShifterSticky24_by_max_26_comb_uid8 is
    port (
        X : in  std_logic_vector(23 downto 0);
        S : in  std_logic_vector(4 downto 0);
        R : out std_logic_vector(25 downto 0);
        Sticky : out std_logic
    );
end entity;

architecture arch of RightShifterSticky24_by_max_26_comb_uid8 is
begin
    process(X, S)
        variable shift_amount : integer range 0 to 31;
        variable extended_x : std_logic_vector(49 downto 0);
        variable shifted : std_logic_vector(49 downto 0);
        variable sticky_bits : std_logic_vector(23 downto 0);
    begin
        shift_amount := to_integer(unsigned(S));
        extended_x := (49 downto 24 => '0') & X;
        
        if shift_amount < 50 then
            shifted := std_logic_vector(shift_right(unsigned(extended_x), shift_amount));
        else
            shifted := (others => '0');
        end if;
        
        R <= shifted(25 downto 0);
        
        sticky_bits := (others => '0');
        if shift_amount > 0 and shift_amount <= 24 then
            sticky_bits(shift_amount-1 downto 0) := X(shift_amount-1 downto 0);
        elsif shift_amount > 24 then
            sticky_bits := X;
        end if;
        
        Sticky <= '0';
        for i in 0 to 23 loop
            if sticky_bits(i) = '1' then
                Sticky <= '1';
            end if;
        end loop;
    end process;
end architecture;

-- ============================================================================
-- 4. IntAdder_27_comb_uid10
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IntAdder_27_comb_uid10 is
    port (
        X : in  std_logic_vector(26 downto 0);
        Y : in  std_logic_vector(26 downto 0);
        Cin : in  std_logic;
        R : out std_logic_vector(26 downto 0)
    );
end entity;

architecture arch of IntAdder_27_comb_uid10 is
begin
    process(X, Y, Cin)
        variable carry : unsigned(0 downto 0);
    begin
        carry(0) := Cin;
        R <= std_logic_vector(unsigned(X) + unsigned(Y) + carry);
    end process;
end architecture;

-- ============================================================================
-- 5. IntAdder_33_comb_uid13 
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IntAdder_33_comb_uid13 is
    port (
        X : in  std_logic_vector(32 downto 0);
        Y : in  std_logic_vector(32 downto 0);
        Cin : in  std_logic;
        R : out std_logic_vector(32 downto 0)
    );
end entity;

architecture arch of IntAdder_33_comb_uid13 is
begin
    process(X, Y, Cin)
        variable carry : unsigned(0 downto 0);
    begin
        carry(0) := Cin;
        R <= std_logic_vector(unsigned(X) + unsigned(Y) + carry);
    end process;
end architecture;

-- ============================================================================
-- 6. IntAdder_33_comb_uid9 (Alias para uid13)
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IntAdder_33_comb_uid9 is
    port (
        X : in  std_logic_vector(32 downto 0);
        Y : in  std_logic_vector(32 downto 0);
        Cin : in  std_logic;
        R : out std_logic_vector(32 downto 0)
    );
end entity;

architecture arch of IntAdder_33_comb_uid9 is
begin
    process(X, Y, Cin)
        variable carry : unsigned(0 downto 0);
    begin
        carry(0) := Cin;
        R <= std_logic_vector(unsigned(X) + unsigned(Y) + carry);
    end process;
end architecture;

-- ============================================================================
-- 7. IntMultiplier_24x24_48_comb_uid5
-- ============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IntMultiplier_24x24_48_comb_uid5 is
    port (
        X : in  std_logic_vector(23 downto 0);
        Y : in  std_logic_vector(23 downto 0);
        R : out std_logic_vector(47 downto 0)
    );
end entity;

architecture arch of IntMultiplier_24x24_48_comb_uid5 is
begin
    process(X, Y)
        variable x_unsigned : unsigned(23 downto 0);
        variable y_unsigned : unsigned(23 downto 0);
        variable result : unsigned(47 downto 0);
    begin
        x_unsigned := unsigned(X);
        y_unsigned := unsigned(Y);
        result := x_unsigned * y_unsigned;
        R <= std_logic_vector(result);
    end process;
end architecture;