export interface MenuItemData{
  name: string
  route: string
}

export function MenuItem({name, route}: MenuItemData) {
  return (
    <li>
      <a href={route}>{name}</a>
    </li>
  )
}