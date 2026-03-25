
layers = [
  {
    name: "background",
    render(ctx, params, scene) {
      const W = scene.viewport.width;
      const H = scene.viewport.height;

      // Deep space gradient
      const bg = ctx.createLinearGradient(0, 0, 0, H);
      bg.addColorStop(0, "#050a1a");
      bg.addColorStop(0.5, "#0a1535");
      bg.addColorStop(1, "#060c22");
      ctx.fillStyle = bg;
      ctx.fillRect(0, 0, W, H);

      // Starfield
      for (let i = 0; i < 180; i++) {
        const x = nc.random(i * 7.1) * W;
        const y = nc.random(i * 13.7) * H;
        const r = nc.random(i * 3.3) * 1.4 + 0.2;
        const alpha = nc.random(i * 5.5) * 0.7 + 0.3;
        ctx.beginPath();
        ctx.arc(x, y, r, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(255,255,255,${alpha})`;
        ctx.fill();
      }
    }
  },
  {
    name: "accent_bar",
    render(ctx, params, scene) {
      const W = scene.viewport.width;
      // Glowing horizontal rule near top
      const y = 108;
      const grad = ctx.createLinearGradient(0, y, W, y);
      grad.addColorStop(0, "rgba(0,200,255,0)");
      grad.addColorStop(0.3, "rgba(0,200,255,0.9)");
      grad.addColorStop(0.7, "rgba(180,80,255,0.9)");
      grad.addColorStop(1, "rgba(180,80,255,0)");
      ctx.strokeStyle = grad;
      ctx.lineWidth = 1.5;
      ctx.beginPath();
      ctx.moveTo(36, y);
      ctx.lineTo(W - 36, y);
      ctx.stroke();
    }
  },
  {
    name: "kicker",
    render(ctx, params, scene) {
      const W = scene.viewport.width;
      const kicker = "STRANGE UNIVERSE";
      ctx.font = `700 10px "Helvetica Neue", Arial, sans-serif`;
      ctx.letterSpacing = "4px";
      const m = nc.measureText(kicker, ctx.font);
      ctx.fillStyle = "rgba(0,210,255,0.85)";
      ctx.fillText(kicker, (W - m.width) / 2, 88);
    }
  },
  {
    name: "headline",
    render(ctx, params, scene) {
      const W = scene.viewport.width;
      const margin = 36;
      const maxW = W - margin * 2;

      // Main headline — two lines
      const line1 = "Neutron Stars";
      const line2 = "Are… Impossible";

      const size1 = nc.fitText(line1, maxW, "Georgia", "bold italic");
      const size2 = nc.fitText(line2, maxW, "Georgia", "bold italic");
      const size = Math.min(size1, size2, 60);

      ctx.font = `bold italic ${size}px "Georgia"`;
      ctx.textAlign = "center";

      // Glowing text effect
      ctx.shadowColor = "rgba(0,200,255,0.6)";
      ctx.shadowBlur = 18;
      const grad = ctx.createLinearGradient(0, 118, 0, 118 + size * 2.2);
      grad.addColorStop(0, "#ffffff");
      grad.addColorStop(0.5, "#c8eeff");
      grad.addColorStop(1, "#a070ff");
      ctx.fillStyle = grad;

      ctx.fillText(line1, W / 2, 100 + size);
      ctx.fillText(line2, W / 2, 100 + size * 2.0);
      ctx.shadowBlur = 0;
      ctx.textAlign = "left";
    }
  },
  {
    name: "subhead",
    render(ctx, params, scene) {
      const W = scene.viewport.width;
      const sub = "The most extreme objects in the known cosmos — and they're real.";
      const size = 13;
      ctx.font = `italic ${size}px "Georgia"`;
      ctx.fillStyle = "rgba(180,230,255,0.75)";
      ctx.textAlign = "center";
      ctx.fillText(sub, W / 2, 252);
      ctx.textAlign = "left";

      // Thin divider below subhead
      ctx.strokeStyle = "rgba(255,255,255,0.12)";
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(36, 266);
      ctx.lineTo(W - 36, 266);
      ctx.stroke();
    }
  },
  {
    name: "body_columns",
    render(ctx, params, scene) {
      const W = scene.viewport.width;
      const margin = 36;
      const gutter = 16;
      const cols = 3;
      const colW = (W - margin * 2 - gutter * (cols - 1)) / cols;
      const bodyTop = 282;
      const fontSize = 10;
      const lineH = fontSize * 1.6;
      ctx.font = `${fontSize}px "Helvetica Neue", Arial, sans-serif`;
      ctx.fillStyle = "rgba(210,230,255,0.88)";

      const colTexts = [
        `Imagine compressing the entire mass of our Sun — roughly 330,000 times Earth's mass — into a sphere no wider than a city. That's a neutron star. These stellar remnants are born from the catastrophic collapse of massive stars during supernova explosions, and they defy almost every intuition we have about matter.\n\nAt their cores, the pressure is so extreme that electrons and protons are crushed together into neutrons. The resulting density is staggering: a single teaspoon of neutron star material would weigh about a billion tonnes on Earth. If you could somehow hold it in your hand — you couldn't — it would fall straight through the planet.`,
        `Neutron stars spin. And they spin fast. Some rotate hundreds of times per second, sweeping beams of radio waves through space like cosmic lighthouses. We call these pulsars. Their timing is so precise that astronomers use them as natural clocks — more accurate than many atomic clocks on Earth.\n\nThe magnetic fields of neutron stars are equally mind-bending. They're roughly a trillion times stronger than Earth's, and in the most extreme variants, called magnetars, these fields can warp the very fabric of spacetime. A magnetar within a few thousand light-years of Earth could strip the data from your credit card.`,
        `In 2017, humanity witnessed something extraordinary: two neutron stars colliding. Detected first as gravitational waves rippling through spacetime, then as a burst of light across every wavelength, the event confirmed a decades-old theory — that neutron star mergers forge heavy elements like gold, platinum, and uranium.\n\nEvery golden ring, every ancient coin, every glittering nugget ever pulled from the earth was born in a collision like that one. We are, in the most literal sense, made of star stuff — but the expensive stuff comes from neutron stars tearing each other apart across the void.`
      ];

      colTexts.forEach((text, ci) => {
        const x = margin + ci * (colW + gutter);
        const paragraphs = text.split("\n\n");
        let yOff = 0;
        paragraphs.forEach((para, pi) => {
          if (pi > 0) yOff += lineH * 0.7;
          const lines = nc.wrapText(para, colW, ctx.font);
          lines.forEach(line => {
            ctx.fillText(line, x, bodyTop + yOff);
            yOff += lineH;
          });
        });
      });
    }
  },
  {
    name: "fact_box",
    render(ctx, params, scene) {
      const W = scene.viewport.width;
      const margin = 36;
      const boxY = 618;
      const boxH = 110;
      const boxW = W - margin * 2;

      // Box background
      ctx.save();
      ctx.beginPath();
      nc.roundRect(ctx, margin, boxY, boxW, boxH, 8);
      ctx.fillStyle = "rgba(0,180,255,0.07)";
      ctx.fill();
      ctx.strokeStyle = "rgba(0,200,255,0.3)";
      ctx.lineWidth = 1;
      ctx.stroke();
      ctx.restore();

      // Label
      ctx.font = `700 8px "Helvetica Neue", Arial, sans-serif`;
      ctx.fillStyle = "rgba(0,210,255,0.9)";
      ctx.fillText("BY THE NUMBERS", margin + 16, boxY + 22);

      // Facts
      const facts = [
        { val: "~20 km", label: "Diameter" },
        { val: "1–2×M☉", label: "Mass" },
        { val: "716 Hz", label: "Fastest Spin" },
        { val: "10¹¹ T", label: "Magnetar Field" },
      ];

      const colW = boxW / facts.length;
      facts.forEach((f, i) => {
        const cx = margin + i * colW + colW / 2;
        ctx.textAlign = "center";

        // Value
        ctx.font = `bold 22px "Georgia"`;
        ctx.fillStyle = "#ffffff";
        ctx.shadowColor = "rgba(0,200,255,0.5)";
        ctx.shadowBlur = 8;
        ctx.fillText(f.val, cx, boxY + 60);
        ctx.shadowBlur = 0;

        // Label
        ctx.font = `9px "Helvetica Neue", Arial, sans-serif`;
        ctx.fillStyle = "rgba(160,210,255,0.8)";
        ctx.fillText(f.label, cx, boxY + 78);
      });

      ctx.textAlign = "left";
    }
  },
  {
    name: "footer",
    render(ctx, params, scene) {
      const W = scene.viewport.width;
      const H = scene.viewport.height;
      const margin = 36;

      ctx.strokeStyle = "rgba(255,255,255,0.1)";
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(margin, H - 36);
      ctx.lineTo(W - margin, H - 36);
      ctx.stroke();

      ctx.font = `9px "Helvetica Neue", Arial, sans-serif`;
      ctx.fillStyle = "rgba(120,160,210,0.6)";
      ctx.fillText("ASTROPHYSICS", margin, H - 22);

      ctx.textAlign = "right";
      ctx.fillText("Illustrated Science Quarterly", W - margin, H - 22);
      ctx.textAlign = "left";
    }
  }
];
