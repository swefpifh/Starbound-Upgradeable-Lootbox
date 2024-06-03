require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
  self.itemList = "itemScrollArea.itemList"
  self.upgradeCurrency = config.getParameter("upgradeCurrency")
  self.upgradeCosts = config.getParameter("upgradeCosts")
  self.upgradeableRelicItems = {}
  self.selectedItem = nil
  populateItemList()
end

function update(dt)
  populateItemList()
end

function upgradeCost(itemConfig)
  if itemConfig == nil then return 0 end
  local currentLevel = itemConfig.parameters.upgradeLevel or 0
  return self.upgradeCosts["upg" .. (currentLevel + 1)] or 0
end

function populateItemList(forceRepop)
  local upgradeableRelicItems = player.itemsWithTag("upgradeableRelic")
  for i = 1, #upgradeableRelicItems do
    upgradeableRelicItems[i].count = 1
  end

  local playerCurrency = player.currency(self.upgradeCurrency)

  if forceRepop or not compare(upgradeableRelicItems, self.upgradeableRelicItems) then
    self.upgradeableRelicItems = upgradeableRelicItems
    widget.clearListItems(self.itemList)
    widget.setButtonEnabled("btnUpgrade", false)

    local showEmptyLabel = true

    for i, item in pairs(self.upgradeableRelicItems) do
      local config = root.itemConfig(item)
      local currentLevel = config.parameters.upgradeLevel or 0

      if currentLevel < 3 then
        showEmptyLabel = false
        local listItem = string.format("%s.%s", self.itemList, widget.addListItem(self.itemList))
        local name = config.config.shortdescription

        widget.setText(string.format("%s.itemName", listItem), name)
        widget.setItemSlotItem(string.format("%s.itemIcon", listItem), item)

        local price = upgradeCost(config)
        widget.setData(listItem, { index = i, price = price, level = currentLevel })
        widget.setVisible(string.format("%s.unavailableoverlay", listItem), price > playerCurrency)
      end
    end

    self.selectedItem = nil
    showRelic(nil)
    widget.setVisible("emptyLabel", showEmptyLabel)
  end
end

function showRelic(item, price)
  local playerCurrency = player.currency(self.upgradeCurrency)
  local enableButton = false

  if item then
    local currentLevel = item.parameters.upgradeLevel or 0
    enableButton = playerCurrency >= price and currentLevel < 3
    local directive = enableButton and "^green;" or "^red;"
    widget.setText("essenceCost", string.format("%s%s / %s", directive, playerCurrency, price))
  else
    widget.setText("essenceCost", string.format("%s / --", playerCurrency))
  end

  widget.setButtonEnabled("btnUpgrade", enableButton)
end

function itemSelected()
  local listItem = widget.getListSelected(self.itemList)
  self.selectedItem = listItem

  if listItem then
    local itemData = widget.getData(string.format("%s.%s", self.itemList, listItem))
    local relicItem = self.upgradeableRelicItems[itemData.index]
    showRelic(relicItem, itemData.price)
  end
end

function doUpgrade()
  if self.selectedItem then
    local selectedData = widget.getData(string.format("%s.%s", self.itemList, self.selectedItem))
    local upgradeItem = self.upgradeableRelicItems[selectedData.index]

    if upgradeItem then
      local currentLevel = upgradeItem.parameters.upgradeLevel or 0
      local price = self.upgradeCosts["upg" .. (currentLevel + 1)]
      if currentLevel < 3 and player.consumeCurrency(self.upgradeCurrency, price) then
        local consumedItem = player.consumeItem(upgradeItem, false, true)
        if consumedItem then
          local upgradedItem = copy(consumedItem)
          upgradedItem.parameters.upgradeLevel = currentLevel + 1
          --upgradedItem.parameters.shortdescription = string.format("%s (UPG%d)", root.itemConfig(upgradedItem).config.shortdescription, currentLevel + 1)
          local newUpgradeParams = root.itemConfig(upgradedItem).config.upgradeParameters["upg" .. (currentLevel + 1)]
          if newUpgradeParams then
            upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, newUpgradeParams)
          end
          player.giveItem(upgradedItem)
        end
      end
    end
    populateItemList(true)
  end
end
