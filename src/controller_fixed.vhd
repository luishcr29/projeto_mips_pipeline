LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY controller IS -- single cycle control decoder
    PORT (
        op, funct : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
        zero : IN STD_LOGIC;
        memtoreg, memwrite : OUT STD_LOGIC;
        pcsrc, alusrc : OUT STD_LOGIC;
        regdst, regwrite : OUT STD_LOGIC;
        jump : OUT STD_LOGIC;
        alucontrol : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) -- EXPANDIDO de 2 para 4 bits
    );
END;

ARCHITECTURE struct OF controller IS
    COMPONENT maindec PORT (
        op : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
        memtoreg, memwrite : OUT STD_LOGIC;
        branch, alusrc : OUT STD_LOGIC;
        regdst, regwrite : OUT STD_LOGIC;
        jump : OUT STD_LOGIC;
        aluop : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
    );
    END COMPONENT;
    
    COMPONENT aludec PORT (
        funct : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
        aluop : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        alucontrol : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) -- 4 bits
    );
    END COMPONENT;
    
    SIGNAL aluop : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL branch : STD_LOGIC;
BEGIN
    md : maindec PORT MAP(
        op => op, 
        memtoreg => memtoreg, 
        memwrite => memwrite, 
        branch => branch, 
        alusrc => alusrc, 
        regdst => regdst, 
        regwrite => regwrite, 
        jump => jump, 
        aluop => aluop
    );
    
    ad : aludec PORT MAP(
        funct => funct, 
        aluop => aluop, 
        alucontrol => alucontrol
    );
    
    pcsrc <= branch AND zero;
END;