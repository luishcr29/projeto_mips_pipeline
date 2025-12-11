LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
ENTITY mux2 IS -- two-input multiplexer
    GENERIC (width : INTEGER := 8);
    PORT (
        d0, d1 : IN STD_LOGIC_VECTOR(width - 1 DOWNTO 0);
        s : IN STD_LOGIC;
        y : OUT STD_LOGIC_VECTOR(width - 1 DOWNTO 0));
END;
ARCHITECTURE behave OF mux2 IS
BEGIN
    y <= d1 WHEN s = '1' ELSE
        d0;
END;