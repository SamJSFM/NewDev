DECLARE 
			@ExchangeRate FLOAT = 0,
			@LMERate1 FLOAT = 0,
			@USDExchangeRate1 FLOAT = 0,
			@AEDExchangeRate1 FLOAT = 0,
			@CopperRate1 FLOAT = 0,
			@CuPremiumCharges1 FLOAT = 455,
			@CuFrieghtCharges1 FLOAT = 5800,
			@A VARCHAR(MAX) = '',
			@B VARCHAR(MAX) = '',
			@C VARCHAR(MAX) = '',
			@D VARCHAR(MAX) = '',
			@Filter VARCHAR(MAX) = '',
			@CompoundCushioning FLOAT=1.02,
			@SiechemMarginPer FLOAT=0.05,			
			@SingleCoreProcessPer VARCHAR(5)=0,
			@MultiCoreProcessPer VARCHAR(5)=0,
			@CableType VARCHAR(100)='PVC Flexible';--'PVC Flexible','Marine Cable','H07RN-F'

		SET @LMERate1 = (SELECT TOP 1 lme_csp FROM LME ORDER BY ID DESC);
		SELECT TOP 1 @USDExchangeRate1 = usd, @AEDExchangeRate1 = AED FROM po_price_units ORDER BY id DESC;
		SET @CopperRate1 = ROUND((((@LMERate1 + @CuPremiumCharges1) + (@CuFrieghtCharges1 / @USDExchangeRate1)) / 1000), 4);
		SET @ExchangeRate = (SELECT TOP 1 USD AS USDRate FROM po_price_units ORDER BY ID DESC);

		IF(@CableType='PVC Flexible')
		BEGIN
			SET @Filter = @Filter + ' AND a.PType IN (''PVC Flexible'',''H05V2V2-F 105 deg'',''H05V2V2-F(LSF) 105 deg'',''H05VV-F 70deg'') ';
			SELECT @SingleCoreProcessPer= ISNULL(MAX(CASE WHEN No_of_Core = '1' THEN ProcessPer ELSE NULL END),0),@MultiCoreProcessPer= ISNULL(MAX(CASE WHEN No_of_Core != '1' THEN ProcessPer ELSE NULL END),0) FROM tbl_Bom_Pricelist1 a WHERE a.PriceList_Type = 'MisterLight' AND a.PType IN ('PVC Flexible','H05V2V2-F 105 deg','H05V2V2-F(LSF) 105 deg','H05VV-F 70deg') GROUP BY Segment,PType;
		END
		ELSE IF(@CableType='Marine Cable')
		BEGIN
			SET @Filter = @Filter + ' AND a.PType IN (''Marine Flexible'') ';
			SELECT @SingleCoreProcessPer= ISNULL(MAX(CASE WHEN No_of_Core = '1' THEN ProcessPer ELSE NULL END),0),@MultiCoreProcessPer= ISNULL(MAX(CASE WHEN No_of_Core != '1' THEN ProcessPer ELSE NULL END),0) FROM tbl_Bom_Pricelist1 a WHERE a.PriceList_Type = 'MisterLight' AND a.PType='Marine Flexible' GROUP BY Segment,PType;
		END
		ELSE IF(@CableType='H07RN-F')
		BEGIN
			SET @Filter = @Filter + ' AND a.PType IN (''H07RN-F'') ';
			SELECT @SingleCoreProcessPer= ISNULL(MAX(CASE WHEN No_of_Core = '1' THEN ProcessPer ELSE NULL END),0),@MultiCoreProcessPer= ISNULL(MAX(CASE WHEN No_of_Core != '1' THEN ProcessPer ELSE NULL END),0) FROM tbl_Bom_Pricelist1 a WHERE a.PriceList_Type = 'MisterLight' AND a.PType='H07RN-F' GROUP BY Segment,PType;
		END



		SELECT @SingleCoreProcessPer AS SingleCorePer,@MultiCoreProcessPer AS MultiCorePer,CableSize, PartNo,ConductorSize, NoOfCore, SizeUnit, CableDescription, ProductType, CopperFactor, ConductorWeight, CopperPrice, CompoundWeight, CompoundPrice, TotalPrice, ProcessPercentage, ProcessingCost, ScrapPercentage, ScrapCost, PackingCharge, InterestOfCredit, Freight, DifferenceInRate, ROUND((ROUND(((TotalPrice + PackingCharge + ProcessingCost + Freight + InterestOfCredit + ScrapCost) * @SiechemMarginPer) + (TotalPrice + PackingCharge + ProcessingCost + Freight + InterestOfCredit + ScrapCost), 3)) * 91.44, 3) AS RollPrice, ROUND(((TotalPrice + PackingCharge + ProcessingCost + Freight + InterestOfCredit + ScrapCost) * @SiechemMarginPer) + (TotalPrice + PackingCharge + ProcessingCost + Freight + InterestOfCredit + ScrapCost), 3) AS CurrentPrice, ROUND(((TotalPrice + PackingCharge + ProcessingCost + Freight + InterestOfCredit + ScrapCost) * @SiechemMarginPer) + (TotalPrice + PackingCharge + ProcessingCost + Freight + InterestOfCredit + ScrapCost), 3) AS QuotedPrice, ROUND(((TotalPrice + PackingCharge + ProcessingCost + Freight + InterestOfCredit + ScrapCost) * @SiechemMarginPer), 3) AS Margin FROM (



SELECT CableSize, PartNo,Conductor_Size AS ConductorSize, NoOfCore, SizeUnit, CableDescription, ProductType, CopperFactor, ConductorWeight, ConductorRate, CopperPrice, ROUND((TapingWeight + InsulationWeight + InnerSheathWeight + InnerSheathTapeWeight + BradingWeight + BradingTapeWeight + FillingWeight + OuterSheathWeight), 3) AS CompoundWeight, ROUND((TapingPrice + InsulationPrice + InnerSheathPrice + InnerSheathTapePrice + BradingPrice + BradingTapePrice + FillingPrice + OuterSheathPrice) / CAST(@ExchangeRate AS VARCHAR(20)), 3) AS CompoundPrice, ROUND((TapingPrice + InsulationPrice + InnerSheathPrice + InnerSheathTapePrice + BradingPrice + BradingTapePrice + FillingPrice + OuterSheathPrice) / CAST(@ExchangeRate AS VARCHAR(20)), 3) + CopperPrice AS TotalPrice, ProcessPercentage, ROUND(((ROUND((TapingPrice + InsulationPrice + InnerSheathPrice + InnerSheathTapePrice + BradingPrice + BradingTapePrice + FillingPrice + OuterSheathPrice) / CAST(@ExchangeRate AS VARCHAR(20)), 3) + CopperPrice) * (ProcessPercentage / 100)), 3) AS ProcessingCost, 2 AS ScrapPercentage, ROUND(((ROUND((TapingPrice + InsulationPrice + InnerSheathPrice + InnerSheathTapePrice + BradingPrice + BradingTapePrice + FillingPrice + OuterSheathPrice) / CAST(@ExchangeRate AS VARCHAR(20)), 3) + CopperPrice) * 0.02), 3) AS ScrapCost, ROUND((dbo.GetPackingCharges(ROUND(RMWeight * 1000, 0)) / CAST(@ExchangeRate AS VARCHAR(20))) / 1000, 3) AS PackingCharge, ROUND(((ROUND((TapingPrice + InsulationPrice + InnerSheathPrice + InnerSheathTapePrice + BradingPrice + BradingTapePrice + FillingPrice + OuterSheathPrice) / CAST(@ExchangeRate AS VARCHAR(20)), 3) + CopperPrice) * 0.01), 3) AS InterestOfCredit, ROUND(((ROUND((TapingPrice + InsulationPrice + InnerSheathPrice + InnerSheathTapePrice + BradingPrice + BradingTapePrice + FillingPrice + OuterSheathPrice) / CAST(@ExchangeRate AS VARCHAR(20)), 3) + CopperPrice) * 0.025), 3) AS Freight, 0.00 AS DifferenceInRate FROM (




SELECT Conductor_Size,a.No_of_Core + 'C x ' + Conductor_Size + 'Sq.mm' AS CableSize, a.PartNo, b.Size_unit AS SizeUnit, b.no_of_core AS NoOfCore, b.Cable_Descrip AS CableDescription, Ptype AS ProductType, CF_Costing AS CopperFactor, ROUND(ISNULL(CBOM / 1000, 0), 3) AS ConductorWeight, ROUND(CAST(@CopperRate1 AS VARCHAR(20)), 2) AS ConductorRate, ROUND((ROUND(CAST(@CopperRate1*@ExchangeRate AS VARCHAR(20)), 4) * ROUND((CBOM), 4)) / 1000, 3) AS CopperPrice, ROUND(ISNULL(Taping_BOM/1000,0),3) AS TapingWeight, ROUND((CASE WHEN ISNULL(Taping_BOM,'')='' THEN 0 ELSE Polyster_Rate END)/1000,3) AS TapingRate, ROUND((ISNULL(Taping_BOM/1000,0)*(CASE WHEN ISNULL(Taping_BOM,'')='' THEN 0 ELSE Polyster_Rate END)),3) AS TapingPrice, ROUND(ISNULL(IBOM / 1000, 0),3) AS InsulationWeight, ROUND(ISNULL(InsRate/1000, 0),3) AS InsulationRate, ROUND((ROUND((ISNULL(IBOM/1000, 0) * ISNULL(InsRate, 0)), 3))*CAST(@CompoundCushioning AS VARCHAR(20)),3) AS InsulationPrice, ROUND(ISNULL(Inner_Sheath_BOM / 1000, 0),3) AS InnerSheathWeight, ROUND(ISNULL(InnerSheath_Rate / 1000, 0),3) AS InnerSheathRate, ROUND((ROUND((ISNULL(Inner_Sheath_BOM/1000, 0) * ISNULL(InnerSheath_Rate, 0)), 3))*CAST(@CompoundCushioning AS VARCHAR(20)),3) AS InnerSheathPrice, ROUND(ISNULL(Insh_Tape_BOM / 1000, 0),3) AS InnerSheathTapeWeight, ROUND(CASE WHEN ISNULL(Insh_Tape_BOM,'')='' THEN 0 ELSE Polyster_Rate END/1000,3) AS InnerSheathTapeRate, ROUND((ROUND((ISNULL(Insh_Tape_BOM/1000, 0) * ISNULL(ROUND((CASE WHEN ISNULL(Insh_Tape_BOM,'')='' THEN 0 ELSE Polyster_Rate END), 3), 0)), 3))*CAST(@CompoundCushioning AS VARCHAR(20)),3) AS InnerSheathTapePrice, ROUND(ISNULL(Brading_BOM / 1000, 0),3) AS BradingWeight, ROUND(ISNULL(ROUND(CASE WHEN ISNULL(Brading_BOM,'')='' THEN '0' ELSE CAST(@CopperRate1 AS VARCHAR(20)) END, 3), 0),3) AS BradingRate, ROUND((ROUND((ISNULL(Brading_BOM/1000, 0) * ISNULL(ROUND((ISNULL(ROUND(CASE WHEN ISNULL(Brading_BOM,'')='' THEN '0' ELSE CAST(@CopperRate1 AS VARCHAR(20)) END, 3), 0)), 3), 0)), 3))*CAST(@CompoundCushioning AS VARCHAR(20)),3) AS BradingPrice, ROUND(ISNULL(Brading_Tape_BOM / 1000, 0),3) AS BradingTapeWeight, ROUND(ISNULL(ROUND((CASE WHEN ISNULL(Brading_Tape_BOM,'')='' THEN 0 ELSE Polyster_Rate END)/1000, 3), 0),3) AS BradingTapeRate, ROUND((ROUND((ISNULL(Brading_Tape_BOM/1000, 0) * ISNULL(ROUND((CASE WHEN ISNULL(Brading_Tape_BOM,'')='' THEN 0 ELSE Polyster_Rate END), 3), 0)), 3))*CAST(@CompoundCushioning AS VARCHAR(20)),3) AS BradingTapePrice, ROUND(ISNULL(FBOM / 1000, 0),3) AS FillingWeight, ROUND(ISNULL(Fill_Rate / 1000, 0),3) AS FillingRate, ROUND((ISNULL(ROUND((ISNULL(FBOM/1000, 0) * Fill_Rate), 3),0))*CAST(@CompoundCushioning AS VARCHAR(20)),3) AS FillingPrice, ROUND(ISNULL(Outer_sheath_BOM / 1000, 0),3) AS OuterSheathWeight, ROUND(ISNULL(OuterSheath_Rate / 1000, 0),3) AS OuterSheathRate, ROUND((ROUND((ISNULL(Outer_sheath_BOM/1000, 0) * ISNULL(OuterSheath_Rate, 0)), 3))*CAST(@CompoundCushioning AS VARCHAR(20)),3) AS OuterSheathPrice, ROUND(ROUND(ISNULL(CBOM / 1000, 0), 3)+ROUND(ISNULL(Taping_BOM/1000,0),3)+ROUND(ISNULL(IBOM / 1000, 0),3)+ROUND(ISNULL(Inner_Sheath_BOM / 1000, 0),3)+ROUND(ISNULL(Insh_Tape_BOM / 1000, 0),3)+ROUND(ISNULL(Brading_BOM / 1000, 0),3)+ROUND(ISNULL(Brading_Tape_BOM / 1000, 0),3)+ROUND(ISNULL(FBOM / 1000, 0),3)+ROUND(ISNULL(Outer_sheath_BOM / 1000, 0),3), 3) AS RMWeight, ISNULL(ProcessPer, 0) AS ProcessPercentage FROM tbl_Bom_Pricelist1 a INNER JOIN tbl_Sales_Price_List2 b ON a.PriceList_Type = b.PriceList_Type AND a.No_of_Core = b.no_of_core AND a.Conductor_Size = b.Size AND a.Shape = b.Shape AND a.PType = b.[Type] WHERE a.PriceList_Type = 'Misterlight' AND a.Partno = b.Partno 



 ) a) b ORDER BY ProductType,CAST(NoOfCore AS INT),CAST(ConductorSize AS FLOAT) ASC 