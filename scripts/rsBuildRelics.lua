function build(directory, config, parameters, level, seed)
  if not parameters.tooltipFields then
    parameters.tooltipFields = {}
  end

  -- Prépare le texte du tooltip
  local tooltipText = ""

  -- Charge les informations du pool de trésors
  local upgradeLevel = parameters.upgradeLevel or config.upgradeLevel or 0
  local upgradeParams = config.upgradeParameters and config.upgradeParameters["upg" .. upgradeLevel] or {}

  if upgradeParams.treasure or config.treasure then
    local poolFilePath = config.poolFilePath
    local pool = upgradeParams.treasure and upgradeParams.treasure.pool or config.treasure.pool
    local success, treasurePools = pcall(root.assetJson, poolFilePath)
    if success then
      local poolInfo = treasurePools[pool]
      if poolInfo and poolInfo[1] then
        local poolDetails = poolInfo[1].pool or poolInfo[1][2].pool
        if poolDetails then
          for _, itemInfo in pairs(poolDetails) do
            local itemConfig = root.itemConfig(itemInfo.item[1])
            local itemName = itemConfig.config.shortdescription or itemInfo.item[1]
            local itemCount = itemInfo.item[2]
            local itemWeight = itemInfo.weight * 100
            local color = getColorForPercentage(itemWeight)
            tooltipText = tooltipText .. string.format("%s x%d ^%s;(%.1f%%)^reset;\n\n", itemName, itemCount, color, itemWeight)
          end
        else
          tooltipText = "No rewards found in the pool."
        end
      else
        tooltipText = "Failed to read pool details."
      end
    else
      tooltipText = "Treasure pool file not found."
    end
  end

  parameters.tooltipFields.treasurepoolLabel = tooltipText

  return config, parameters
end

function getColorForPercentage(percentage)
  if percentage <= 10 then
    return "red"
  elseif percentage <= 20 then
    return "orange"
  elseif percentage <= 50 then
    return "yellow"
  elseif percentage <= 80 then
    return "blue"
  else
    return "green"
  end
end
