import LayoutShell from './App.vue';
import Home from './pages/Home.vue';
import About from './pages/About.vue';
import Events from './pages/Events.vue';
import EventShow from './pages/EventShow.vue';
import Archive from './pages/Archive.vue';
import News from './pages/News.vue';
import Services from './pages/Services.vue';
import Contact from './pages/Contact.vue';

export const CLASSIC_LAYOUT_ID = 'classic';

export function createClassicRoute() {
  return {
    path: '/',
    component: LayoutShell,
    meta: { layout: CLASSIC_LAYOUT_ID },
    children: [
      { path: '', name: 'home', component: Home, meta: { title: '首頁' } },
      { path: 'about', name: 'about', component: About, meta: { title: '關於本廟' } },
      { path: 'events', name: 'events', component: Events, meta: { title: '活動資訊' } },
      { path: 'events/:slug', name: 'event', component: EventShow, meta: { title: '活動資訊詳情' } },
      { path: 'archive', name: 'archive', component: Archive, meta: { title: '活動回顧' } },
      { path: 'news', name: 'news', component: News, meta: { title: '最新消息' } },
      { path: 'services', name: 'services', component: Services, meta: { title: '祈福服務' } },
      { path: 'contact', name: 'contact', component: Contact, meta: { title: '聯絡 / 交通' } }
    ]
  };
}
