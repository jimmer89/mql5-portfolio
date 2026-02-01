# 📋 Propuestas Listas para Enviar — Feb 2026

## 1. QVET Indicator — $30+ (⭐ SOLO 2 aplicaciones)
> Indicador de momentum con volatilidad y volumen, sin repaint

---

Hi,

I've read your QVET spec and can build this. Here's my approach:

**Technical plan:**
- Core engine: combine price momentum (ROC/derivative), ATR-based volatility, and tick/real volume into a single composite score
- Clean visual output: histogram or oscillator with color-coded zones (strong momentum, exhaustion, neutral)
- No repaint — all calculations on confirmed bars only, with optional real-time unconfirmed bar preview
- Works on any symbol and timeframe as requested

**What I'd deliver:**
- `.mq5` source code + compiled `.ex5`
- All visual settings configurable via inputs (colors, periods, sensitivity, alert toggles)
- Alert system: push, email, sound, and popup (configurable per signal type)
- Brief usage guide with recommended settings

**Timeline:** 5-7 days

I build clean, documented indicators — you can check my Market Structure indicator (HH/HL/LH/LL + BOS/CHoCH detection) on my profile for reference.

Portfolio: https://github.com/jimmer89/mql5-portfolio

Let me know if you have questions about the approach.

Jaume

---

## 2. Scalping Bot Donchian + RSI — $30-500

---

Hi,

This is right in my wheelhouse — I have a published Double RSI EA on the MQL5 Market already, so I'm very familiar with RSI-based filtering for scalping.

**My approach for your bot:**
- Donchian channel for dynamic SL/TP: calculate channel on N periods, SL at opposite band, TP at configurable ratio
- RSI volatility filter: skip entries when RSI is in dead zone (40-60) or when ATR is below threshold — avoids choppy/low-quality setups
- Asset-specific parameters: all key values (Donchian period, RSI period/levels, SL/TP multipliers, session hours) as input parameters for easy optimization per symbol
- Scalping-safe: spread filter, max slippage, cooldown between trades

**Deliverables:**
- Working `.mq5` source + `.ex5`
- Full input parameters for Strategy Tester optimization
- Documentation explaining logic and recommended settings

**Timeline:** 7-10 days depending on final spec details

Check my published EAs: https://www.mql5.com/en/users/whitechocolate
GitHub: https://github.com/jimmer89/mql5-portfolio

Happy to discuss specifics.

Jaume

---

## 3. EMA50/200 Trend + M15 Pullback EA — $40+

---

Hi,

Clean strategy, I like it. Here's how I'd implement it:

**Technical approach:**
- H1 trend detection: EMA50 vs EMA200 cross checked on each M15 tick using iMA handles
- M15 entry: detect pullback to EMA50 zone (configurable proximity), then confirm with bullish/bearish candle pattern (engulfing, pin bar, or simple close direction)
- SL at last swing high/low of the pullback candle — I'd use a small lookback to find the actual extreme, not just the single candle
- TP = 2× SL distance (RR 1:2 as specified), with optional breakeven at 1:1

**Risk management:**
- Position sizing based on SL distance + risk % per trade
- Magic number isolation for multi-EA accounts
- Max 1 position at a time (configurable)

**Deliverables:**
- `.mq5` source + `.ex5`
- All parameters configurable
- Brief doc with recommended settings for backtesting

**Timeline:** 5-7 days

I focus on clean, auditable code with no martingale or hidden logic. Check my profile for published EAs and open-source portfolio.

Jaume

---

## 4. ZigZag Custom Object-Based EA — $30+

---

Hi,

I understand exactly what you need — a self-contained EA that draws its own ZigZag using chart objects, no external indicator dependency.

**My approach:**
- Custom ZigZag engine: swing detection using N-bar lookback on both sides, calculating highs/lows directly from price data
- Object-based rendering: `OBJ_TREND` lines drawn between confirmed swing points, auto-updated as new swings form
- All visual on EA attach — no manual indicator needed, ZigZag appears immediately
- Clean object management: proper naming convention, cleanup on removal (OnDeinit)

I recently built a Market Structure indicator that does exactly this kind of work — detecting swing HH/HL/LH/LL and drawing BOS/CHoCH lines as chart objects. Same architecture applies here.

I'd need to see your full spec to confirm the trading logic built on top of the ZigZag. Could you share the complete requirements?

**Timeline:** 7-10 days (depends on trading logic complexity)

Portfolio: https://github.com/jimmer89/mql5-portfolio

Jaume

---

## 5. Modification to Existing System — $70+ (⭐ SOLO 1 aplicación)

---

Hi,

I'm comfortable modifying existing MQL5 systems — I regularly work with inherited codebases and have published a MQL4→MQL5 migration guide covering common patterns.

I can deliver both the modified indicator and EA with trade stacking and trailing profit as you described. Happy to review the source code and detailed rules document before confirming scope and timeline.

Could you share the source code and the rules document? Once I see the logic, I can give you a precise estimate.

**What I typically deliver:**
- Modified `.mq5` source + compiled `.ex5` for both indicator and EA
- Trade stacking with configurable max positions and entry rules
- Trailing profit: configurable activation level + trail step
- Clean documentation of changes made

Portfolio: https://github.com/jimmer89/mql5-portfolio
Published EAs: https://www.mql5.com/en/users/whitechocolate

Jaume

---

## 📌 Tips al enviar
1. **Personaliza** el [CLIENT_NAME] si ves su nombre en el post
2. **Adapta el presupuesto** — para los primeros 3 jobs, sé agresivo en precio (objetivo = reviews)
3. **Responde rápido** — primera buena propuesta suele ganar
4. **Pregunta algo específico** del spec para demostrar que lo leíste
