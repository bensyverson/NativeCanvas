const W = 612, H = 792;
const margin = 36;

const events = [
  { label: "Big Bang",              date: "Jan 1",            yearsAgo: "13.8 billion",  t: 0.0 },
  { label: "First stars ignite",    date: "Jan 22",           yearsAgo: "13.6 billion",  t: 21/365 },
  { label: "Milky Way forms",       date: "Mar 16",           yearsAgo: "13.5 billion",  t: 74/365 },
  { label: "Sun & Earth form",      date: "Sep 2",            yearsAgo: "4.6 billion",   t: 244/365 },
  { label: "First life on Earth",   date: "Sep 21",           yearsAgo: "3.8 billion",   t: 263/365 },
  { label: "Complex cells",         date: "Dec 5",            yearsAgo: "1.7 billion",   t: 338/365 },
  { label: "Multicellular life",    date: "Dec 14",           yearsAgo: "1.0 billion",   t: 347/365 },
  { label: "First fish",            date: "Dec 19",           yearsAgo: "530 million",   t: 352/365 },
  { label: "First land plants",     date: "Dec 20",           yearsAgo: "475 million",   t: 353/365 },
  { label: "First reptiles",        date: "Dec 23",           yearsAgo: "310 million",   t: 356/365 },
  { label: "First dinosaurs",       date: "Dec 25",           yearsAgo: "230 million",   t: 358/365 },
  { label: "First mammals",         date: "Dec 26",           yearsAgo: "200 million",   t: 359/365 },
  { label: "Dinosaurs extinct",     date: "Dec 30",           yearsAgo: "66 million",    t: 363/365 },
  { label: "First humans",          date: "Dec 31, 10:30 PM", yearsAgo: "2.5 million",   t: (364 + 22.5/24)/365 },
  { label: "All recorded history",  date: "Dec 31, 11:59 PM", yearsAgo: "~12,000",        t: (364 + 23.983/24)/365 },
];

const months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];

layers = [
  {
    name: "background",
    render(ctx, params, scene) {
      const grad = ctx.createLinearGradient(0, 0, 0, H);
      grad.addColorStop(0,   "#03030f");
      grad.addColorStop(0.5, "#080820");
      grad.addColorStop(1,   "#0a0416");
      ctx.fillStyle = grad;
      ctx.fillRect(0, 0, W, H);

      // Stars
      for (let i = 0; i < 300; i++) {
        const x = nc.random(i * 7.13) * W;
        const y = nc.random(i * 13.37) * H;
        const r = nc.random(i * 3.71) * 1.3 + 0.2;
        const alpha = nc.random(i * 5.91) * 0.65 + 0.25;
        ctx.beginPath();
        ctx.arc(x, y, r, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(255,255,255,${alpha})`;
        ctx.fill();
      }

      // Subtle nebula glow in the month bar region
      const nebGrad = ctx.createRadialGradient(W * 0.72, 168, 0, W * 0.72, 168, 90);
      nebGrad.addColorStop(0,   "rgba(80,30,160,0.18)");
      nebGrad.addColorStop(0.5, "rgba(40,10,100,0.08)");
      nebGrad.addColorStop(1,   "rgba(0,0,0,0)");
      ctx.fillStyle = nebGrad;
      ctx.fillRect(0, 130, W, 80);

      const nebGrad2 = ctx.createRadialGradient(W * 0.18, 158, 0, W * 0.18, 158, 60);
      nebGrad2.addColorStop(0,   "rgba(20,60,180,0.12)");
      nebGrad2.addColorStop(1,   "rgba(0,0,0,0)");
      ctx.fillStyle = nebGrad2;
      ctx.fillRect(0, 130, W, 80);
    }
  },

  {
    name: "title",
    render(ctx, params, scene) {
      ctx.textAlign = "center";

      ctx.font = `bold 10px "Helvetica Neue"`;
      ctx.fillStyle = "rgba(150,180,255,0.65)";
      ctx.fillText("C A R L   S A G A N ' S", W/2, margin + 16);

      const ts = Math.min(nc.fitText("COSMIC CALENDAR", W - margin*2, "Georgia", "bold italic"), 56);
      ctx.font = `bold italic ${ts}px "Georgia"`;
      const g = ctx.createLinearGradient(margin, 0, W - margin, 0);
      g.addColorStop(0,   "#90baff");
      g.addColorStop(0.5, "#ffffff");
      g.addColorStop(1,   "#ffd090");
      ctx.fillStyle = g;
      ctx.fillText("COSMIC CALENDAR!", W/2, margin + 16 + ts + 2);

      ctx.font = `italic 12px "Georgia"`;
      ctx.fillStyle = "rgba(200,215,255,0.72)";
      ctx.fillText("If the history of the universe were compressed into a single year\u2026", W/2, margin + 16 + ts + 2 + 22);
    }
  },

  {
    name: "month_bar",
    render(ctx, params, scene) {
      const barTop = 138;
      const barLeft = margin + 4;
      const barW = W - margin * 2 - 8;
      const barH = 62;
      const cellW = barW / 12;

      months.forEach((m, i) => {
        const x = barLeft + i * cellW;
        const isDec = (i === 11);

        if (isDec) {
          const g = ctx.createLinearGradient(x, barTop, x, barTop + barH);
          g.addColorStop(0, "rgba(80,35,130,0.9)");
          g.addColorStop(1, "rgba(35,8,75,0.95)");
          ctx.fillStyle = g;
        } else {
          ctx.fillStyle = `rgba(18,28,68,${0.38 + i * 0.022})`;
        }
        ctx.fillRect(x, barTop, cellW - 1, barH);

        // Subtle mid-cell vertical tick (billion-year scale feel)
        ctx.beginPath();
        ctx.moveTo(x + cellW / 2, barTop + 18);
        ctx.lineTo(x + cellW / 2, barTop + barH - 14);
        ctx.strokeStyle = "rgba(100,130,255,0.07)";
        ctx.lineWidth = 0.5;
        ctx.stroke();

        // Month label
        ctx.textAlign = "center";
        ctx.font = `bold 9px "Helvetica Neue"`;
        ctx.fillStyle = isDec ? "#ffcc88" : "rgba(155,175,255,0.82)";
        ctx.fillText(m, x + cellW / 2, barTop + 13);

        // Event dots
        events.forEach(ev => {
          const mi = Math.min(Math.floor(ev.t * 12), 11);
          if (mi === i) {
            const frac = (ev.t * 12) - mi;
            const dotX = x + frac * cellW;
            const dotY = barTop + barH - 10;
            const isLate = ev.t > 0.993;
            // Glow
            const glowGrad = ctx.createRadialGradient(dotX, dotY, 0, dotX, dotY, 8);
            glowGrad.addColorStop(0, isLate ? "rgba(255,140,40,0.4)" : "rgba(255,220,100,0.3)");
            glowGrad.addColorStop(1, "rgba(0,0,0,0)");
            ctx.fillStyle = glowGrad;
            ctx.fillRect(dotX - 8, dotY - 8, 16, 16);
            // Dot
            ctx.beginPath();
            ctx.arc(dotX, dotY, ev.t > 0.99 ? 4 : 3, 0, Math.PI * 2);
            ctx.fillStyle = isLate ? "#ff9944" : "#ffdd88";
            ctx.fill();
          }
        });
      });

      // Outer border
      ctx.strokeStyle = "rgba(100,130,255,0.35)";
      ctx.lineWidth = 1;
      ctx.strokeRect(barLeft, barTop, barW, barH);

      // Column dividers
      for (let i = 1; i < 12; i++) {
        ctx.beginPath();
        ctx.moveTo(barLeft + i * cellW, barTop);
        ctx.lineTo(barLeft + i * cellW, barTop + barH);
        ctx.strokeStyle = "rgba(100,130,255,0.18)";
        ctx.lineWidth = 0.5;
        ctx.stroke();
      }

      // Gradient time bar
      const tbY = barTop + barH + 8;
      const tbH = 5;
      const tbGrad = ctx.createLinearGradient(barLeft, 0, barLeft + barW, 0);
      tbGrad.addColorStop(0,   "#111166");
      tbGrad.addColorStop(0.7, "#3a1898");
      tbGrad.addColorStop(1,   "#ff8833");
      ctx.fillStyle = tbGrad;
      nc.roundRect(ctx, barLeft, tbY, barW, tbH, 2);
      ctx.fill();

      ctx.textAlign = "left";
      ctx.font = `bold 8px "Helvetica Neue"`;
      ctx.fillStyle = "rgba(140,165,255,0.55)";
      ctx.fillText("BIG BANG", barLeft + 2, tbY - 3);

      ctx.textAlign = "right";
      ctx.fillStyle = "#ff8833";
      ctx.fillText("NOW \u2192", barLeft + barW - 2, tbY - 3);
    }
  },

  {
    name: "event_list",
    render(ctx, params, scene) {
      const startY = 232;
      const left = margin + 8;
      const colW = W - margin * 2 - 8;
      const rowH = 31;

      // Three columns: dot+date | label | years ago
      const dateChipX = left + 18;
      const dateChipW = 98;   // tighter — just wide enough for longest date
      const labelX = dateChipX + dateChipW + 10;
      const labelW = 190;
      const yearsX = labelX + labelW;

      // Section header
      ctx.textAlign = "left";
      ctx.font = `bold 9px "Helvetica Neue"`;
      ctx.fillStyle = "rgba(140,165,255,0.55)";
      ctx.fillText("K E Y   E V E N T S   O N   T H E   C O S M I C   C A L E N D A R", left, startY - 8);

      ctx.beginPath();
      ctx.moveTo(left, startY - 4);
      ctx.lineTo(left + colW, startY - 4);
      ctx.strokeStyle = "rgba(100,130,255,0.25)";
      ctx.lineWidth = 0.5;
      ctx.stroke();

      // Column headers
      ctx.font = `bold 8px "Helvetica Neue"`;
      ctx.fillStyle = "rgba(120,145,220,0.45)";
      ctx.textAlign = "left";
      ctx.fillText("DATE", dateChipX + 4, startY + 10);
      ctx.fillText("EVENT", labelX, startY + 10);
      ctx.fillText("ACTUAL TIME AGO", yearsX, startY + 10);

      const rowStart = startY + 16;

      for (let i = 0; i < events.length; i++) {
        const ev = events[i];
        const y = rowStart + i * rowH;
        const isLate = ev.t > 0.993;
        const isMid  = ev.t > 0.9;

        // Alternating row bg
        if (i % 2 === 0) {
          ctx.fillStyle = "rgba(255,255,255,0.028)";
          ctx.fillRect(left - 4, y, colW + 8, rowH);
        }

        const cy = y + rowH / 2;

        // Colored dot
        ctx.beginPath();
        ctx.arc(left + 6, cy, 4, 0, Math.PI * 2);
        ctx.fillStyle = isLate ? "#ff9944" : (isMid ? "#88ccff" : "#5577ff");
        ctx.fill();

        // Date pill — sized to content, not stretched
        const dateMeasure = nc.measureText(ev.date, `bold 9px "Helvetica Neue"`);
        const pillW = dateMeasure.width + 14;
        ctx.fillStyle = isLate ? "rgba(110,50,0,0.65)" : "rgba(25,35,95,0.65)";
        nc.roundRect(ctx, dateChipX, cy - 9, pillW, 17, 3);
        ctx.fill();

        ctx.font = `bold 9px "Helvetica Neue"`;
        ctx.textAlign = "left";
        ctx.fillStyle = isLate ? "#ffcc88" : "rgba(155,190,255,0.9)";
        ctx.fillText(ev.date, dateChipX + 7, cy + 4);

        // Event label
        ctx.font = `13px "Georgia"`;
        ctx.fillStyle = isLate ? "#ffe8c8" : "rgba(225,232,255,0.88)";
        ctx.fillText(ev.label, labelX, cy + 4);

        // Years ago — right-aligned within its column, dimmer style
        ctx.font = `italic 10px "Georgia"`;
        ctx.textAlign = "left";
        ctx.fillStyle = isLate ? "rgba(255,180,80,0.65)" : "rgba(140,165,220,0.6)";
        ctx.fillText(ev.yearsAgo + (ev.yearsAgo.startsWith("~") ? " yrs ago" : " yrs ago"), yearsX, cy + 4);
      }
    }
  },

  {
    name: "footer",
    render(ctx, params, scene) {
      const y = H - margin + 6;
      ctx.textAlign = "center";
      ctx.font = `italic 10px "Georgia"`;
      ctx.fillStyle = "rgba(140,165,255,0.42)";
      ctx.fillText(
        "All of recorded human history \u2014 wars, empires, agriculture, art \u2014 fits in the final 14 seconds of December 31.",
        W/2, y
      );
    }
  }
];
