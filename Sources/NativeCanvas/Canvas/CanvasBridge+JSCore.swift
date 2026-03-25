//
//  CanvasBridge+JSCore.swift
//  NativeCanvas
//

import JavaScriptCore

extension CanvasBridge {
    /// Installs all Canvas 2D methods and property accessors onto a `JSValue` object.
    public func installInto(_ ctxValue: JSValue) {
        jsContext = ctxValue.context
        installMethods(onto: ctxValue)
        installProperties(onto: ctxValue)
    }

    // MARK: - Methods

    private func installMethods(onto ctx: JSValue) {
        let saveBlock: @convention(block) () -> Void = { [weak self] in self?.save() }
        ctx.setObject(saveBlock, forKeyedSubscript: "save" as NSString)

        let restoreBlock: @convention(block) () -> Void = { [weak self] in self?.restore() }
        ctx.setObject(restoreBlock, forKeyedSubscript: "restore" as NSString)

        let fillRectBlock: @convention(block) (Double, Double, Double, Double) -> Void = { [weak self] x, y, w, h in
            self?.fillRect(x: x, y: y, width: w, height: h)
        }
        ctx.setObject(fillRectBlock, forKeyedSubscript: "fillRect" as NSString)

        let strokeRectBlock: @convention(block) (Double, Double, Double, Double) -> Void = { [weak self] x, y, w, h in
            self?.strokeRect(x: x, y: y, width: w, height: h)
        }
        ctx.setObject(strokeRectBlock, forKeyedSubscript: "strokeRect" as NSString)

        let clearRectBlock: @convention(block) (Double, Double, Double, Double) -> Void = { [weak self] x, y, w, h in
            self?.clearRect(x: x, y: y, width: w, height: h)
        }
        ctx.setObject(clearRectBlock, forKeyedSubscript: "clearRect" as NSString)

        let beginPathBlock: @convention(block) () -> Void = { [weak self] in self?.beginPath() }
        ctx.setObject(beginPathBlock, forKeyedSubscript: "beginPath" as NSString)

        let moveToBlock: @convention(block) (Double, Double) -> Void = { [weak self] x, y in self?.moveTo(x: x, y: y) }
        ctx.setObject(moveToBlock, forKeyedSubscript: "moveTo" as NSString)

        let lineToBlock: @convention(block) (Double, Double) -> Void = { [weak self] x, y in self?.lineTo(x: x, y: y) }
        ctx.setObject(lineToBlock, forKeyedSubscript: "lineTo" as NSString)

        let closePathBlock: @convention(block) () -> Void = { [weak self] in self?.closePath() }
        ctx.setObject(closePathBlock, forKeyedSubscript: "closePath" as NSString)

        let bezierCurveToBlock: @convention(block) (Double, Double, Double, Double, Double, Double) -> Void = { [weak self] cp1x, cp1y, cp2x, cp2y, x, y in
            self?.bezierCurveTo(cp1x: cp1x, cp1y: cp1y, cp2x: cp2x, cp2y: cp2y, x: x, y: y)
        }
        ctx.setObject(bezierCurveToBlock, forKeyedSubscript: "bezierCurveTo" as NSString)

        let quadraticCurveToBlock: @convention(block) (Double, Double, Double, Double) -> Void = { [weak self] cpx, cpy, x, y in
            self?.quadraticCurveTo(cpx: cpx, cpy: cpy, x: x, y: y)
        }
        ctx.setObject(quadraticCurveToBlock, forKeyedSubscript: "quadraticCurveTo" as NSString)

        let arcBlock: @convention(block) (Double, Double, Double, Double, Double, Bool) -> Void = { [weak self] x, y, r, start, end, ccw in
            self?.arc(x: x, y: y, radius: r, startAngle: start, endAngle: end, counterclockwise: ccw)
        }
        ctx.setObject(arcBlock, forKeyedSubscript: "arc" as NSString)

        let arcToBlock: @convention(block) (Double, Double, Double, Double, Double) -> Void = { [weak self] x1, y1, x2, y2, r in
            self?.arcTo(x1: x1, y1: y1, x2: x2, y2: y2, radius: r)
        }
        ctx.setObject(arcToBlock, forKeyedSubscript: "arcTo" as NSString)

        let rectBlock: @convention(block) (Double, Double, Double, Double) -> Void = { [weak self] x, y, w, h in
            self?.rect(x: x, y: y, width: w, height: h)
        }
        ctx.setObject(rectBlock, forKeyedSubscript: "rect" as NSString)

        let fillBlock: @convention(block) () -> Void = { [weak self] in self?.fill() }
        ctx.setObject(fillBlock, forKeyedSubscript: "fill" as NSString)

        let strokeBlock: @convention(block) () -> Void = { [weak self] in self?.stroke() }
        ctx.setObject(strokeBlock, forKeyedSubscript: "stroke" as NSString)

        let clipBlock: @convention(block) () -> Void = { [weak self] in self?.clip() }
        ctx.setObject(clipBlock, forKeyedSubscript: "clip" as NSString)

        let translateBlock: @convention(block) (Double, Double) -> Void = { [weak self] x, y in self?.translate(x: x, y: y) }
        ctx.setObject(translateBlock, forKeyedSubscript: "translate" as NSString)

        let rotateBlock: @convention(block) (Double) -> Void = { [weak self] angle in self?.rotate(angle: angle) }
        ctx.setObject(rotateBlock, forKeyedSubscript: "rotate" as NSString)

        let scaleBlock: @convention(block) (Double, Double) -> Void = { [weak self] x, y in self?.scale(x: x, y: y) }
        ctx.setObject(scaleBlock, forKeyedSubscript: "scale" as NSString)

        let setTransformBlock: @convention(block) (Double, Double, Double, Double, Double, Double) -> Void = { [weak self] a, b, c, d, e, f in
            self?.setTransform(a: a, b: b, c: c, d: d, e: e, f: f)
        }
        ctx.setObject(setTransformBlock, forKeyedSubscript: "setTransform" as NSString)

        let resetTransformBlock: @convention(block) () -> Void = { [weak self] in self?.resetTransform() }
        ctx.setObject(resetTransformBlock, forKeyedSubscript: "resetTransform" as NSString)

        let fillTextBlock: @convention(block) (String, Double, Double, JSValue) -> Void = { [weak self] text, x, y, maxWidthVal in
            let maxWidth: Double? = (!maxWidthVal.isUndefined && !maxWidthVal.isNull && maxWidthVal.isNumber)
                ? maxWidthVal.toDouble()
                : nil
            self?.fillText(text: text, x: x, y: y, maxWidth: maxWidth)
        }
        ctx.setObject(fillTextBlock, forKeyedSubscript: "fillText" as NSString)

        let strokeTextBlock: @convention(block) (String, Double, Double, JSValue) -> Void = { [weak self] text, x, y, maxWidthVal in
            let maxWidth: Double? = (!maxWidthVal.isUndefined && !maxWidthVal.isNull && maxWidthVal.isNumber)
                ? maxWidthVal.toDouble()
                : nil
            self?.strokeText(text: text, x: x, y: y, maxWidth: maxWidth)
        }
        ctx.setObject(strokeTextBlock, forKeyedSubscript: "strokeText" as NSString)

        let measureTextBlock: @convention(block) (String) -> [String: Double] = { [weak self] text in
            self?.measureText(text) ?? ["width": 0]
        }
        ctx.setObject(measureTextBlock, forKeyedSubscript: "measureText" as NSString)

        installGradientMethods(onto: ctx)
        installDrawImageMethod(onto: ctx)
    }

    // MARK: - Gradient Methods

    private func installGradientMethods(onto ctx: JSValue) {
        guard let jsCtx = ctx.context else { return }

        let createLinGradBlock: @convention(block) (Double, Double, Double, Double) -> JSValue = { [weak self] x0, y0, x1, y1 in
            guard let self, let jsCtx = jsContext else { return JSValue(undefinedIn: nil) }
            let gradient = createLinearGradient(x0: x0, y0: y0, x1: x1, y1: y1)
            let id = UUID().uuidString
            gradients[id] = gradient

            let gradObj = JSValue(newObjectIn: jsCtx)!
            gradObj.setValue(id, forProperty: "__gradientID")
            gradObj.setValue(true, forProperty: "__isGradient")

            let addStopBlock: @convention(block) (Double, String) -> Void = { [weak self] offset, colorStr in
                guard let self else { return }
                if let cgColor = CSSColorParser.parse(colorStr, in: colorSpace) {
                    gradient.addColorStop(offset: CGFloat(offset), color: cgColor)
                }
            }
            gradObj.setObject(addStopBlock, forKeyedSubscript: "addColorStop" as NSString)
            return gradObj
        }
        ctx.setObject(createLinGradBlock, forKeyedSubscript: "createLinearGradient" as NSString)

        let createRadGradBlock: @convention(block) (Double, Double, Double, Double, Double, Double) -> JSValue = { [weak self] x0, y0, r0, x1, y1, r1 in
            guard let self, let jsCtx = jsContext else { return JSValue(undefinedIn: nil) }
            let gradient = createRadialGradient(x0: x0, y0: y0, r0: r0, x1: x1, y1: y1, r1: r1)
            let id = UUID().uuidString
            gradients[id] = gradient

            let gradObj = JSValue(newObjectIn: jsCtx)!
            gradObj.setValue(id, forProperty: "__gradientID")
            gradObj.setValue(true, forProperty: "__isGradient")

            let addStopBlock: @convention(block) (Double, String) -> Void = { [weak self] offset, colorStr in
                guard let self else { return }
                if let cgColor = CSSColorParser.parse(colorStr, in: colorSpace) {
                    gradient.addColorStop(offset: CGFloat(offset), color: cgColor)
                }
            }
            gradObj.setObject(addStopBlock, forKeyedSubscript: "addColorStop" as NSString)
            return gradObj
        }
        ctx.setObject(createRadGradBlock, forKeyedSubscript: "createRadialGradient" as NSString)

        _ = jsCtx
    }

    // MARK: - drawImage Method

    private func installDrawImageMethod(onto ctx: JSValue) {
        let nativeDrawImage: @convention(block) () -> Void = { [weak self] in
            guard let self, let jsCtx = jsContext else { return }
            guard let callerArgs = jsCtx.evaluateScript("__drawImageArgs") else { return }
            guard callerArgs.isArray else { return }

            let argCount = callerArgs.forProperty("length")?.toInt32() ?? 0
            guard argCount >= 3 else { return }

            let key = callerArgs.atIndex(0)?.toString() ?? ""
            var numericArgs: [Double] = []
            for i in 1 ..< Int(argCount) {
                numericArgs.append(callerArgs.atIndex(i)?.toDouble() ?? 0)
            }
            drawImageByKey(key, args: numericArgs)
        }

        guard let jsCtx = ctx.context else { return }
        jsCtx.setObject(nativeDrawImage, forKeyedSubscript: "__nativeDrawImage" as NSString)
        jsCtx.evaluateScript("""
            (function(ctx) {
                ctx.drawImage = function() {
                    __drawImageArgs = Array.prototype.slice.call(arguments);
                    __nativeDrawImage();
                };
            })
        """)?.call(withArguments: [ctx])
    }

    // MARK: - Properties

    private func installProperties(onto ctx: JSValue) {
        guard let jsContext = ctx.context else { return }

        jsContext.evaluateScript("""
            function __defineAccessor(obj, name, getter, setter) {
                Object.defineProperty(obj, name, {
                    get: getter,
                    set: setter,
                    configurable: true
                });
            }
        """)

        guard let defineFn = jsContext.objectForKeyedSubscript("__defineAccessor") else { return }

        let fillGet: @convention(block) () -> String = { [weak self] in self?.fillStyleString ?? "#000000" }
        let fillSetNative: @convention(block) () -> Void = { [weak self] in
            guard let self, let jsCtx = self.jsContext else { return }
            guard let val = jsCtx.evaluateScript("__fillStyleVal") else { return }
            if val.isString, let str = val.toString() {
                setFillStyle(str)
            } else if val.isObject, let gradID = val.forProperty("__gradientID")?.toString(),
                      let gradient = gradients[gradID]
            {
                fillGradient = gradient
            }
        }

        jsContext.setObject(fillSetNative, forKeyedSubscript: "__fillStyleSetNative" as NSString)
        jsContext.evaluateScript("""
            (function(obj, getter) {
                Object.defineProperty(obj, 'fillStyle', {
                    get: getter,
                    set: function(v) { __fillStyleVal = v; __fillStyleSetNative(); },
                    configurable: true
                });
            })
        """)?.call(withArguments: [ctx, unsafeBitCast(fillGet, to: AnyObject.self)])

        let strokeGet: @convention(block) () -> String = { [weak self] in self?.strokeStyleString ?? "#000000" }
        let strokeSetNative: @convention(block) () -> Void = { [weak self] in
            guard let self, let jsCtx = self.jsContext else { return }
            guard let val = jsCtx.evaluateScript("__strokeStyleVal") else { return }
            if val.isString, let str = val.toString() {
                setStrokeStyle(str)
            } else if val.isObject, let gradID = val.forProperty("__gradientID")?.toString(),
                      let gradient = gradients[gradID]
            {
                strokeGradient = gradient
            }
        }

        jsContext.setObject(strokeSetNative, forKeyedSubscript: "__strokeStyleSetNative" as NSString)
        jsContext.evaluateScript("""
            (function(obj, getter) {
                Object.defineProperty(obj, 'strokeStyle', {
                    get: getter,
                    set: function(v) { __strokeStyleVal = v; __strokeStyleSetNative(); },
                    configurable: true
                });
            })
        """)?.call(withArguments: [ctx, unsafeBitCast(strokeGet, to: AnyObject.self)])

        let lwGet: @convention(block) () -> Double = { [weak self] in Double(self?.lineWidth ?? 1.0) }
        let lwSet: @convention(block) (Double) -> Void = { [weak self] v in self?.lineWidth = CGFloat(v) }
        defineFn.call(withArguments: [ctx, "lineWidth", unsafeBitCast(lwGet, to: AnyObject.self), unsafeBitCast(lwSet, to: AnyObject.self)])

        let lcGet: @convention(block) () -> String = { [weak self] in self?.lineCapString ?? "butt" }
        let lcSet: @convention(block) (String) -> Void = { [weak self] v in self?.lineCapString = v }
        defineFn.call(withArguments: [ctx, "lineCap", unsafeBitCast(lcGet, to: AnyObject.self), unsafeBitCast(lcSet, to: AnyObject.self)])

        let ljGet: @convention(block) () -> String = { [weak self] in self?.lineJoinString ?? "miter" }
        let ljSet: @convention(block) (String) -> Void = { [weak self] v in self?.lineJoinString = v }
        defineFn.call(withArguments: [ctx, "lineJoin", unsafeBitCast(ljGet, to: AnyObject.self), unsafeBitCast(ljSet, to: AnyObject.self)])

        let gaGet: @convention(block) () -> Double = { [weak self] in Double(self?.globalAlpha ?? 1.0) }
        let gaSet: @convention(block) (Double) -> Void = { [weak self] v in self?.globalAlpha = CGFloat(v) }
        defineFn.call(withArguments: [ctx, "globalAlpha", unsafeBitCast(gaGet, to: AnyObject.self), unsafeBitCast(gaSet, to: AnyObject.self)])

        let gcoGet: @convention(block) () -> String = { [weak self] in self?.globalCompositeOperationString ?? "source-over" }
        let gcoSet: @convention(block) (String) -> Void = { [weak self] v in self?.globalCompositeOperationString = v }
        defineFn.call(withArguments: [ctx, "globalCompositeOperation", unsafeBitCast(gcoGet, to: AnyObject.self), unsafeBitCast(gcoSet, to: AnyObject.self)])

        let fontGet: @convention(block) () -> String = { [weak self] in self?.currentState.fontString ?? "10px sans-serif" }
        let fontSet: @convention(block) (String) -> Void = { [weak self] v in self?.currentState.fontString = v }
        defineFn.call(withArguments: [ctx, "font", unsafeBitCast(fontGet, to: AnyObject.self), unsafeBitCast(fontSet, to: AnyObject.self)])

        let taGet: @convention(block) () -> String = { [weak self] in self?.currentState.textAlign ?? "start" }
        let taSet: @convention(block) (String) -> Void = { [weak self] v in self?.currentState.textAlign = v }
        defineFn.call(withArguments: [ctx, "textAlign", unsafeBitCast(taGet, to: AnyObject.self), unsafeBitCast(taSet, to: AnyObject.self)])

        let tbGet: @convention(block) () -> String = { [weak self] in self?.currentState.textBaseline ?? "alphabetic" }
        let tbSet: @convention(block) (String) -> Void = { [weak self] v in self?.currentState.textBaseline = v }
        defineFn.call(withArguments: [ctx, "textBaseline", unsafeBitCast(tbGet, to: AnyObject.self), unsafeBitCast(tbSet, to: AnyObject.self)])

        let scGet: @convention(block) () -> String = { [weak self] in self?.shadowColorString ?? "rgba(0, 0, 0, 0)" }
        let scSet: @convention(block) (String) -> Void = { [weak self] v in self?.shadowColorString = v }
        defineFn.call(withArguments: [ctx, "shadowColor", unsafeBitCast(scGet, to: AnyObject.self), unsafeBitCast(scSet, to: AnyObject.self)])

        let sbGet: @convention(block) () -> Double = { [weak self] in Double(self?.shadowBlur ?? 0) }
        let sbSet: @convention(block) (Double) -> Void = { [weak self] v in self?.shadowBlur = CGFloat(v) }
        defineFn.call(withArguments: [ctx, "shadowBlur", unsafeBitCast(sbGet, to: AnyObject.self), unsafeBitCast(sbSet, to: AnyObject.self)])

        let soxGet: @convention(block) () -> Double = { [weak self] in Double(self?.shadowOffsetX ?? 0) }
        let soxSet: @convention(block) (Double) -> Void = { [weak self] v in self?.shadowOffsetX = CGFloat(v) }
        defineFn.call(withArguments: [ctx, "shadowOffsetX", unsafeBitCast(soxGet, to: AnyObject.self), unsafeBitCast(soxSet, to: AnyObject.self)])

        let soyGet: @convention(block) () -> Double = { [weak self] in Double(self?.shadowOffsetY ?? 0) }
        let soySet: @convention(block) (Double) -> Void = { [weak self] v in self?.shadowOffsetY = CGFloat(v) }
        defineFn.call(withArguments: [ctx, "shadowOffsetY", unsafeBitCast(soyGet, to: AnyObject.self), unsafeBitCast(soySet, to: AnyObject.self)])

        jsContext.evaluateScript("delete __defineAccessor")
    }
}
