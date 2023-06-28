import {MenuItemData, MenuItem} from "./MenuItem"
import "./TopBar.css"

export default function TopBar({menuItems}: {menuItems: MenuItemData[]}) {
  const menuElements = menuItems.map(
    item => <MenuItem key={item.name} name={item.name} route={item.route} />
  );
  return (
    <nav>
      <div className="hero">
        <div className="centerpiece">
          <div className="textContainer">
            <div className="text">
            Jared Bean
            </div>
          </div>
        </div>
      </div>
      <ul>
        {menuElements}
      </ul>
    </nav>
  )
}