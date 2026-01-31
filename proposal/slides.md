---
theme: seriph
background: https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&q=80&w=2072
class: text-center
highlighter: shiki
lineNumbers: true
drawings:
  persist: false
transition: slide-left
title: AI-Assisted Decision Support System
mdc: true
---

# AI-Assisted DSS
### Decision Making Simplified through Conversational Intelligence

<div class="pt-12">
  <span @click="$slidev.nav.next" class="px-2 py-1 rounded cursor-pointer hover:bg-white/10" style="color: #03A9F4">
    Press Space for next page <carbon:arrow-right class="inline"/>
  </span>
</div>

<div class="abs-br m-6 flex gap-2">
  <div class="text-sm opacity-50">Prima Adi & Ade Dwi</div>
</div>

---
transition: fade-out
---

# The Problem

Making complex decisions is often overwhelming and mathematically taxing.

<v-clicks>

- **Information Overload**: Too many criteria and alternatives to process manually.
- **Mathematical Complexity**: Algorithms like SAW, WP, and TOPSIS are powerful but hard to implement for non-experts.
- **Decision Fatigue**: The mental burden of weighting factors and comparing options often leads to procrastination or poor choices.

</v-clicks>

---
transition: slide-up
---

# The Idea: AI-Assisted DSS

Bridging the gap between human intuition and mathematical precision.

<div class="grid grid-cols-2 gap-4 mt-8">
  <div class="bg-blue-50/10 p-4 rounded-lg border border-blue-200/20">
    <h3 class="text-blue-400 mb-2">Conversational UI</h3>
    <p class="text-sm">Instead of complex forms, users interact with a friendly AI assistant to define their decision context.</p>
  </div>
  <div class="bg-orange-50/10 p-4 rounded-lg border border-orange-200/20">
    <h3 class="text-orange-400 mb-2">Automated Calculation</h3>
    <p class="text-sm">The system handles the heavy lifting of multi-criteria decision-making algorithms.</p>
  </div>
</div>

---

# How It Works

A seamless 4-step process to reach a decision.

<div class="flex flex-col gap-4 mt-4">

<div class="flex items-center gap-4">
  <div class="w-10 h-10 rounded-full bg-blue-500 flex items-center justify-center font-bold">1</div>
  <div>
    <h3 class="font-bold">Discovery</h3>
    <p class="text-sm opacity-80">AI asks insightful questions to identify criteria, weights, and alternatives.</p>
  </div>
</div>

<div class="flex items-center gap-4">
  <div class="w-10 h-10 rounded-full bg-indigo-500 flex items-center justify-center font-bold">2</div>
  <div>
    <h3 class="font-bold">Structuring</h3>
    <p class="text-sm opacity-80">Data is organized into a matrix ready for mathematical processing.</p>
  </div>
</div>

<div class="flex items-center gap-4">
  <div class="w-10 h-10 rounded-full bg-purple-500 flex items-center justify-center font-bold">3</div>
  <div>
    <h3 class="font-bold">Algorithmic Processing</h3>
    <p class="text-sm opacity-80">SAW, WP, or TOPSIS methods are applied to rank the alternatives.</p>
  </div>
</div>

<div class="flex items-center gap-4">
  <div class="w-10 h-10 rounded-full bg-pink-500 flex items-center justify-center font-bold">4</div>
  <div>
    <h3 class="font-bold">Guided Decision</h3>
    <p class="text-sm opacity-80">AI explains the results clearly, helping the user make the final choice.</p>
  </div>
</div>

</div>

---

# Multi-Method Analysis

Different perspectives for a more robust decision.

| Method | Best For... |
| --- | --- |
| **Simple Additive Weighting (SAW)** | Basic proportional weighting and straightforward comparisons. |
| **Weighted Product (WP)** | Decisions where criteria relationships are multiplicative. |
| **TOPSIS** | Choosing the alternative closest to the ideal solution and farthest from the negative-ideal. |

<p class="mt-4 text-sm italic">The AI guides the user to the most appropriate method or provides a consolidated view.</p>

---
layout: center
class: text-center
---

# Why It Wins?

<v-clicks>

### **Mathematically Grounded**
### **Socially Intelligent**
### **Decisively Faster**

</v-clicks>

---
layout: center
---

# Application Preview

<div class="flex justify-center mt-4">
  <img src="/ss.png" class="rounded-lg shadow-xl border border-white/10 w-2/3" />
</div>

---
layout: end
---

# Thank You!

**Decision Making, Reimagined.**

<div class="mt-8">
  <p class="font-bold">Proposed by:</p>
  <p>Prima Adi</p>
  <p>Ade Dwi</p>
</div>
