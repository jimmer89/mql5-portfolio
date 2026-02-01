# Freelance Proposal Templates

## Template 1: EA Development from Scratch

---

Hi [CLIENT_NAME],

I've read your requirements carefully and can build this EA for you.

**My approach for this project:**

- [BRIEF_TECHNICAL_APPROACH — e.g., "I'd implement the entry logic using iMA handles for the crossover detection, with CTrade for order execution and proper position management"]
- Risk management: configurable SL/TP, optional trailing stop, magic number isolation
- Clean code with comments so you can review and modify later
- Full input parameters for all key settings

**What you'll get:**
- Working .mq5 source code + compiled .ex5
- Input parameters for easy optimization in Strategy Tester
- Brief documentation explaining the logic and parameters

**Timeline:** [X] days from project start

**About me:**
I develop MQL5 Expert Advisors and indicators. I have published EAs on the MQL5 Market and maintain an open-source portfolio of trading tools:
- MQL5 Market: https://www.mql5.com/en/users/whitechocolate
- GitHub: https://github.com/jimmer89/mql5-portfolio

Happy to answer any questions before we start.

Best,
Jaume

---

## Template 2: Custom Indicator

---

Hi [CLIENT_NAME],

I can build this indicator for you. Here's how I'd approach it:

**Technical plan:**
- [DESCRIBE_APPROACH — e.g., "Swing detection using N-bar lookback on both sides, with configurable sensitivity"]
- Visual elements: [LABELS/ARROWS/LINES/PANEL — based on what they need]
- Alert system: push, email, sound, and popup notifications (configurable)
- Works on any symbol and timeframe

**Deliverables:**
- .mq5 source code + .ex5 compiled indicator
- All visual settings configurable via inputs (colors, sizes, toggle on/off)
- Brief usage guide

**Timeline:** [X] days

I recently published a Market Structure indicator (HH/HL/LH/LL + BOS/CHoCH detection) that you can check out on my profile. I'm comfortable building chart analysis tools.

Portfolio: https://github.com/jimmer89/mql5-portfolio

Let me know if you have questions.

Jaume

---

## Template 3: MQL4 to MQL5 Migration

---

Hi [CLIENT_NAME],

I can handle this MQL4 → MQL5 migration for you.

**What the migration involves:**
- Replacing deprecated MQL4 functions with MQL5 equivalents (OrderSend → CTrade, iMA → indicator handles, etc.)
- Updating the trading logic to use MQL5's position management model
- Adapting to MQL5's event-driven architecture (OnTick, OnTrade, OnInit)
- Testing that the migrated version produces equivalent behavior

**Common pitfalls I'll handle:**
- MQL5's handle-based indicator system (iMA returns a handle, not a value)
- Different order/position model (no OrderSelect by ticket like MQL4)
- Timer and event differences
- Proper resource cleanup in OnDeinit

**Deliverables:**
- Fully migrated .mq5 source code
- Compiled .ex5
- Notes on any behavioral differences between the MQL4 and MQL5 versions

**Timeline:** [X] days (depends on complexity of the original EA)

I maintain a MQL4→MQL5 migration guide with code examples and a function equivalency table:
https://github.com/jimmer89/mql5-portfolio/tree/master/05-mql4-to-mql5-guide

Happy to take a look at the source code before confirming scope.

Jaume

---

## Tips for proposals

1. **Always read the full project description** — reference specific details they mentioned
2. **Be specific about your approach** — don't just say "I can do it", explain HOW
3. **Keep it short** — 150-250 words max, nobody reads walls of text
4. **Link your work** — GitHub + MQL5 profile every time
5. **Price the first 3 jobs aggressively** — $30-50, goal is reviews not money
6. **Respond fast** — first good proposal often wins
7. **Ask one smart question** — shows you actually read the spec
