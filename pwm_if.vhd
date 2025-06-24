----------------------------------------------------------------------------------
-- Company: Myway Plus Corporation 
-- Module Name: pwm_if
-- Target Devices: Kintex-7 xc7k70t
-- Tool Versions: Vivado 2016.4
-- Create Date: 2017/01/10
-- Revision: 2.0
-- Last Modified: 2025/06/23
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library unisim;
use unisim.vcomponents.all;

entity pwm_if is
    port (
        CLK_IN           : in std_logic;
        RESET_IN        : in std_logic;
        nPWM_UP_OUT    : out std_logic; --nUSER_OPT_OUT(0)
        nPWM_UN_OUT    : out std_logic; --nUSER_OPT_OUT(1)
        nPWM_VP_OUT    : out std_logic; --nUSER_OPT_OUT(2)
        nPWM_VN_OUT    : out std_logic; --nUSER_OPT_OUT(3)
        nPWM_WP_OUT    : out std_logic; --nUSER_OPT_OUT(4)
        nPWM_WN_OUT    : out std_logic; --nUSER_OPT_OUT(5)
        nUSER_OPT_OUT : out std_logic_vector (23 downto 6);

        UPDATE    : in std_logic;
        CARRIER   : in std_logic_vector (15 downto 0);
        U_REF    : in std_logic_vector (15 downto 0);
        V_REF    : in std_logic_vector (15 downto 0);
        W_REF    : in std_logic_vector (15 downto 0);
        DEADTIME : in std_logic_vector (12 downto 0);
        GATE_EN  : in std_logic;

        -- my costom
            TPDM : in std_logic_vector (15 downto 0);
            M : in std_logic_vector (3 downto 0);
            N : in std_logic_vector (3 downto 0);
            TD : in std_logic_vector (7 downto 0)
    );
end pwm_if;

architecture Behavioral of pwm_if is

    component deadtime_if is
        Port (
            CLK_IN     : in std_logic;
            RESET_IN : in std_logic;
            DT           : in std_logic_vector(12 downto 0);
            G_IN        : in std_logic;
            G_OUT      : out std_logic
        );
    end component;

    component dstspdm_ff_if is
        Port (
            CLK_IN     : in std_logic;
            RESET_IN : in std_logic;
            TPDM       : in std_logic_vector (15 downto 0);
            M           : in std_logic_vector (3 downto 0);
            N           : in std_logic_vector (3 downto 0);
            TD          : in std_logic_vector (7 downto 0);
            S1_IN    : in std_logic;
            S2_IN    : in std_logic;
            S3_IN    : in std_logic;
            S4_IN    : in std_logic;
            S5_IN    : in std_logic;
            S6_IN    : in std_logic;
            S1_OUT   : out std_logic;
            S2_OUT   : out std_logic;
            S3_OUT   : out std_logic;
            S4_OUT   : out std_logic;
            S5_OUT   : out std_logic;
            S6_OUT   : out std_logic
        );
    end component;

    signal carrier_cnt_max_b : std_logic_vector (15 downto 0);
    signal carrier_cnt_max_bb : std_logic_vector (15 downto 0);
    signal carrier_cnt       : std_logic_vector (15 downto 0);
    signal carrier_up_down : std_logic;
    signal u_ref_b : std_logic_vector (15 downto 0);
    signal v_ref_b : std_logic_vector (15 downto 0);
    signal w_ref_b : std_logic_vector (15 downto 0);
    signal u_ref_bb : std_logic_vector (15 downto 0);
    signal v_ref_bb : std_logic_vector (15 downto 0);
    signal w_ref_bb : std_logic_vector (15 downto 0);
    signal pwm_up : std_logic;
    signal pwm_un : std_logic;
    signal pwm_vp : std_logic;
    signal pwm_vn : std_logic;
    signal pwm_wp : std_logic;
    signal pwm_wn : std_logic;
    signal pwm_up_dt : std_logic := '0';
    signal pwm_un_dt : std_logic := '0';
    signal pwm_vp_dt : std_logic := '0';
    signal pwm_vn_dt : std_logic := '0';
    signal pwm_wp_dt : std_logic := '0';
    signal pwm_wn_dt : std_logic := '0';
    signal dt_b : std_logic_vector (12 downto 0);
    signal dt_bb : std_logic_vector (12 downto 0);
    signal gate_en_b : std_logic := '0';

    -- my costom
    signal pwm_up_dsts_ff : std_logic := '0';
    signal pwm_un_dsts_ff : std_logic := '0';
    signal pwm_vp_dsts_ff : std_logic := '0';
    signal pwm_vn_dsts_ff : std_logic := '0';
    signal pwm_wp_dsts_ff : std_logic := '0';
    signal pwm_wn_dsts_ff : std_logic := '0';

    -- my attribute
    attribute mark_debug : string;
    attribute mark_debug of pwm_up : signal is "true";
    attribute mark_debug of pwm_un : signal is "true";
    attribute mark_debug of pwm_vp : signal is "true";
    attribute mark_debug of pwm_vn : signal is "true";
    attribute mark_debug of pwm_wp : signal is "true";
    attribute mark_debug of pwm_wn : signal is "true";
    attribute mark_debug of pwm_up_dt : signal is "true";
    attribute mark_debug of pwm_un_dt : signal is "true";
    attribute mark_debug of pwm_vp_dt : signal is "true";
    attribute mark_debug of pwm_vn_dt : signal is "true";
    attribute mark_debug of pwm_wp_dt : signal is "true";
    attribute mark_debug of pwm_wn_dt : signal is "true";
    attribute mark_debug of pwm_up_dsts_ff : signal is "true";
    attribute mark_debug of pwm_un_dsts_ff : signal is "true";
    attribute mark_debug of pwm_vp_dsts_ff : signal is "true";
    attribute mark_debug of pwm_vn_dsts_ff : signal is "true";
    attribute mark_debug of pwm_wp_dsts_ff : signal is "true";
    attribute mark_debug of pwm_wn_dsts_ff : signal is "true";



begin

    process(CLK_IN)
    begin
        if CLK_IN'event and CLK_IN = '1' then
            if RESET_IN = '1' then
                gate_en_b <= '0';
            else
                gate_en_b <= GATE_EN;
            end if;

            if RESET_IN = '1' then
                carrier_cnt_max_b  <= X"1388"; -- 10kHz
                carrier_cnt        <= X"0000";
                u_ref_b <= X"09C4"; -- m = 0.5
                v_ref_b <= X"09C4"; -- m = 0.5
                w_ref_b <= X"09C4"; -- m = 0.5
                dt_b <= '0' & X"190"; -- 4us
            elsif UPDATE = '1' then
                carrier_cnt_max_b <= CARRIER;
                u_ref_b <= U_REF;
                v_ref_b <= V_REF;
                w_ref_b <= W_REF;
                dt_b <= DEADTIME;
            end if;       

            if RESET_IN = '1' then
                carrier_up_down <= '1';
                carrier_cnt_max_bb <= X"1388";
            elsif carrier_cnt = X"0001" and carrier_up_down = '0' then
                carrier_up_down <= '1';
            elsif carrier_cnt >= (carrier_cnt_max_bb -1) and carrier_up_down = '1' then
                carrier_up_down <= '0';
                carrier_cnt_max_bb <= carrier_cnt_max_b;
            end if;

            if RESET_IN = '1' then
                carrier_cnt <= X"0000";
            elsif carrier_up_down = '1' then
                carrier_cnt <= carrier_cnt + 1;
            else
                carrier_cnt <= carrier_cnt - 1;
            end if;   

        end if;
    end process;

    process(CLK_IN)
    begin
        if CLK_IN'event and CLK_IN = '1' then
            if RESET_IN = '1' then
                u_ref_bb <= X"09C4"; -- m = 0.5
                v_ref_bb <= X"09C4"; -- m = 0.5
                w_ref_bb <= X"09C4"; -- m = 0.5
            elsif carrier_cnt = (carrier_cnt_max_bb -1) and carrier_up_down = '1' then
                u_ref_bb <= u_ref_b;
                v_ref_bb <= v_ref_b;
                w_ref_bb <= w_ref_b;
            end if;

            if RESET_IN = '1' then
                pwm_up <= '0';
                pwm_un <= '0';
                pwm_vp <= '0';
                pwm_vn <= '0';
                pwm_wp <= '0';
                pwm_wn <= '0';
            elsif carrier_cnt >= u_ref_bb then
                pwm_up <= '1';
                pwm_un <= '0';
                pwm_vp <= '0';
                pwm_vn <= '1';
                pwm_wp <= '0';
                pwm_wn <= '0';
            else
                pwm_up <= '0';
                pwm_un <= '1';
                pwm_vp <= '1';
                pwm_vn <= '0';
                pwm_wp <= '0';
                pwm_wn <= '0';
            end if;

            -- if RESET_IN = '1' then
            --     pwm_vp <= '0';
            --     pwm_vn <= '0';
            -- elsif carrier_cnt >= v_ref_bb then
            --     pwm_vp <= '0';
            --     pwm_vn <= '1';
            -- else
            --     pwm_vp <= '1';
            --     pwm_vn <= '0';
            -- end if;

            -- if RESET_IN = '1' then
            --     pwm_wp <= '0';
            --     pwm_wn <= '0';
            -- elsif carrier_cnt >= w_ref_bb then
            --     pwm_wp <= '0';
            --     pwm_wn <= '1';
            -- else
            --     pwm_wp <= '1';
            --     pwm_wn <= '0';
            -- end if;

        end if;
    end process;

    process(CLK_IN)
    begin
        if CLK_IN'event and CLK_IN = '1' then
            if RESET_IN = '1' then
                dt_bb <= '0' & X"190"; -- 4us
            elsif carrier_cnt = (carrier_cnt_max_bb -1) then
                dt_bb <= dt_b;
            end if;
        end if;
    end process;

    dsts : dstspdm_ff_if
        port map (
            CLK_IN     => CLK_IN,
            RESET_IN => RESET_IN,
            TPDM       => TPDM,
            M           => M,
            N           => N,
            TD          => TD,
            S1_IN    => pwm_up,
            S2_IN    => pwm_un,
            S3_IN    => pwm_vp,
            S4_IN    => pwm_vn,
            S5_IN    => pwm_wp,
            S6_IN    => pwm_wn,
            S1_OUT   => pwm_up_dsts_ff,
            S2_OUT   => pwm_un_dsts_ff,
            S3_OUT   => pwm_vp_dsts_ff,
            S4_OUT   => pwm_vn_dsts_ff,
            S5_OUT   => pwm_wp_dsts_ff,
            S6_OUT   => pwm_wn_dsts_ff
        );

    dt_up : deadtime_if port map (CLK_IN => CLK_IN, RESET_IN => RESET_IN, DT => dt_bb, G_IN => pwm_up, G_OUT => pwm_up_dt);
    dt_un : deadtime_if port map (CLK_IN => CLK_IN, RESET_IN => RESET_IN, DT => dt_bb, G_IN => pwm_un, G_OUT => pwm_un_dt);
    dt_vp : deadtime_if port map (CLK_IN => CLK_IN, RESET_IN => RESET_IN, DT => dt_bb, G_IN => pwm_vp, G_OUT => pwm_vp_dt);
    dt_vn : deadtime_if port map (CLK_IN => CLK_IN, RESET_IN => RESET_IN, DT => dt_bb, G_IN => pwm_vn, G_OUT => pwm_vn_dt);
    dt_wp : deadtime_if port map (CLK_IN => CLK_IN, RESET_IN => RESET_IN, DT => dt_bb, G_IN => pwm_wp, G_OUT => pwm_wp_dt);
    dt_wn : deadtime_if port map (CLK_IN => CLK_IN, RESET_IN => RESET_IN, DT => dt_bb, G_IN => pwm_wn, G_OUT => pwm_wn_dt);

    nPWM_UP_OUT <= not (pwm_up_dt and gate_en_b);
    nPWM_UN_OUT <= not (pwm_un_dt and gate_en_b);
    nPWM_VP_OUT <= not (pwm_vp_dt and gate_en_b);
    nPWM_VN_OUT <= not (pwm_vn_dt and gate_en_b);
    nPWM_WP_OUT <= not (pwm_wp_dt and gate_en_b);
    nPWM_WN_OUT <= not (pwm_wn_dt and gate_en_b);

    nUSER_OPT_OUT(6) <= not (pwm_up_dt and gate_en_b);
    nUSER_OPT_OUT(7) <= not (pwm_un_dt and gate_en_b);
    nUSER_OPT_OUT(8) <= not (pwm_vp_dt and gate_en_b);
    nUSER_OPT_OUT(9) <= not (pwm_vn_dt and gate_en_b);
    nUSER_OPT_OUT(10) <= not (pwm_wp_dt and gate_en_b);
    nUSER_OPT_OUT(11) <= not (pwm_wn_dt and gate_en_b);
    nUSER_OPT_OUT(12) <= not (pwm_up_dt and gate_en_b);
    nUSER_OPT_OUT(13) <= not (pwm_un_dt and gate_en_b);
    nUSER_OPT_OUT(14) <= not (pwm_vp_dt and gate_en_b);
    nUSER_OPT_OUT(15) <= not (pwm_vn_dt and gate_en_b);
    nUSER_OPT_OUT(16) <= not (pwm_wp_dt and gate_en_b);
    nUSER_OPT_OUT(17) <= not (pwm_wn_dt and gate_en_b);
    nUSER_OPT_OUT(18) <= not (pwm_up_dt and gate_en_b);
    nUSER_OPT_OUT(19) <= not (pwm_un_dt and gate_en_b);
    nUSER_OPT_OUT(20) <= not (pwm_vp_dt and gate_en_b);
    nUSER_OPT_OUT(21) <= not (pwm_vn_dt and gate_en_b);
    nUSER_OPT_OUT(22) <= not (pwm_wp_dt and gate_en_b);
    nUSER_OPT_OUT(23) <= not (pwm_wn_dt and gate_en_b);

end Behavioral;


----------------------------------------------------------------------------------
--Deadtime module
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library unisim;
use unisim.vcomponents.all;

entity deadtime_if is
    Port (
        CLK_IN     : in std_logic;
        RESET_IN : in std_logic;
        DT           : in std_logic_vector(12 downto 0);
        G_IN        : in std_logic;
        G_OUT      : out std_logic
        );
end deadtime_if;

architecture behavioral of deadtime_if is
signal d_g_in: std_logic;
signal cnt: std_logic_vector(12 downto 0);
signal gate: std_logic;

begin

    process(CLK_IN)
    begin
        if (CLK_IN'event and CLK_IN='1') then
            if RESET_IN = '1' then
                d_g_in <= '0';
            else
                d_g_in <= G_IN;
            end if;

            if RESET_IN = '1' then
                cnt   <= "0000000000001";
                gate <= '0';
            elsif (d_g_in = '0' and G_IN = '1') then
                cnt   <= "0000000000001";
                gate <= '0';
            elsif (cnt >= DT) then
                cnt   <= "1111111111111";
                gate <= d_g_in;
            elsif (cnt /= "1111111111111") then
                cnt   <= cnt + 1;
                gate <= '0';
            else
                gate <= d_g_in;
            end if;
        end if;
    end process;

    G_OUT <= gate;

end behavioral;

----------------------------------------------------------------------------------
-- dstspdm_ff_if module
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dstspdm_ff_if is
    Port (
        CLK_IN     : in std_logic;
        RESET_IN : in std_logic;
        TPDM       : in std_logic_vector (15 downto 0);
        M           : in std_logic_vector (3 downto 0);
        N           : in std_logic_vector (3 downto 0);
        TD          : in std_logic_vector (7 downto 0);
        S1_IN    : in std_logic;
        S2_IN    : in std_logic;
        S3_IN    : in std_logic;
        S4_IN    : in std_logic;
        S5_IN    : in std_logic;
        S6_IN    : in std_logic;
        S1_OUT   : out std_logic;
        S2_OUT   : out std_logic;
        S3_OUT   : out std_logic;
        S4_OUT   : out std_logic;
        S5_OUT   : out std_logic;
        S6_OUT   : out std_logic
    );
end dstspdm_ff_if;

architecture Behavioral of dstspdm_ff_if is

  signal inv_output : std_logic := '0';
  signal rect_output : std_logic := '0';

  signal in1_delayed : std_logic := '0';
  signal in2_delayed : std_logic := '0';
  signal in3_delayed : std_logic := '0';
  signal in4_delayed : std_logic := '0';
  signal s1_edge_ref : std_logic := '0';

  signal inv_counter : unsigned(15 downto 0) := (others => '0');
  signal m_count : unsigned(3 downto 0) := (others => '0');

  signal in56_delay_line : std_logic_vector(294 downto 0) := (others => '0');
  signal s5_edge_ref : std_logic := '0';

  signal rect_counter : unsigned(15 downto 0) := (others => '0');
  signal n_count : unsigned(3 downto 0) := (others => '0');

begin

  -- S1~S4用の PDM 制御 (inv_output) maybe ok?
  process(CLK_IN)
  begin
    if rising_edge(CLK_IN) then
      if RESET_IN = '1' then
        in1_delayed <= '0';
        in2_delayed <= '0';
        in3_delayed <= '0';
        in4_delayed <= '0';
        s1_edge_ref <= '0';
        inv_output <= '0';
        inv_counter <= (others => '0');
        m_count <= (others => '0');
      else
        in1_delayed <= S1_IN;
        in2_delayed <= S2_IN;
        in3_delayed <= S3_IN;
        in4_delayed <= S4_IN;
        s1_edge_ref <= S1_IN; -- エッジ検出用のリファレンス

        if (S1_IN /= s1_edge_ref) then  -- エッジ検出
          if inv_counter >= unsigned(TPDM) then
            inv_counter <= (others => '0');
            m_count <= unsigned(M);
          else
            inv_counter <= inv_counter + 1;
            if inv_counter < m_count then
              inv_output <= '0';
            else
              inv_output <= '1';
            end if;
          end if;
        end if;

      end if;
    end if;
  end process;

  -- S5~S6用の 整流モード制御 (rect_output)
  process(CLK_IN)
  begin
    if rising_edge(CLK_IN) then
      if RESET_IN = '1' then
        in56_delay_line <= (others => '0');
        s5_edge_ref <= '0';
        rect_output <= '0';
        rect_counter <= (others => '0');
        n_count <= (others => '0');
      else
        -- 295クロック遅延（in56_delay_lineの最上位ビット（294)が所望の信号）
        in56_delay_line <= in56_delay_line(293 downto 0) & S1_IN; -- 1ビットずらし（下294+1ビット目にS1_INを格納）

        if (in56_delay_line(294) /= s5_edge_ref) then  -- エッジ検出
          if rect_counter >= unsigned(TPDM) then
            rect_counter <= (others => '0');
            n_count <= unsigned(N);
          else
            rect_counter <= rect_counter + 1;
            if rect_counter < n_count then
              rect_output <= '0';
            else
              rect_output <= '1';
            end if;
          end if;
        end if;

        s5_edge_ref <= in56_delay_line(294);
      end if;
    end if;
  end process;

  -- 出力信号制御 ok!
  S1_OUT <= in1_delayed when inv_output = '1' else '0';
  S2_OUT <= in2_delayed when inv_output = '1' else '1';
  S3_OUT <= in3_delayed when inv_output = '1' else '0';
  S4_OUT <= in4_delayed when inv_output = '1' else '1';

  S5_OUT <= '0' when rect_output = '1' else '1';
  S6_OUT <= '0' when rect_output = '1' else '1';

end Behavioral;
