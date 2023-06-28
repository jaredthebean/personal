import {MenuItemData} from "../components/MenuItem"
import TopBar from "../components/TopBar"
const MENU_ITEMS: MenuItemData[] = [
  {
    name: "Home",
    route: "/",
  },
  {
    name: "Blog",
    route:"/blog",
  },
  {
    name: "Curriculum vitae",
    route: "/cv"
  },
  {
    name: "Fun",
    route: "/fun"
  }
]
export default function Home() {
  return (
    <>
    <TopBar menuItems={MENU_ITEMS} />
    <div>
      {/* TODO: Make an image + text component */}
      Blah, Blah, Blah
    </div>

    </>
  )
}