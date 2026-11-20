(()=>{const {Node,Sprite,A,Gfx,rgba,white,label}=SK;
class TargetGame extends MiniScene{
 setupGame(){this.duration=45;this.st=this.seats.map(s=>{const p=NK.panel(s,s.color),cw=Math.min((p.w-30)/3,100),ch=Math.min((p.h-130)/2,78),st={p,cw,ch,cells:[],sel:-1,T:0,vals:[],cpu:2};
  for(let i=0;i<6;i++){const x=(i%3-1)*cw,y=p.cy-34-(Math.floor(i/3)-.5)*ch,c=new Sprite(Gfx.pill(cw-8,ch-8,white(1,.14),white(1,.4),16,false),cw-8,ch-8);c.x=x;c.y=y;c.z=2;s.field.add(c);const l=label('0',30,'#fff');l.x=x;l.y=y;l.z=4;s.field.add(l);st.cells.push({c,l,x,y})}
  st.tl=label('',46,s.color);st.tl.y=p.cy+p.h/2-48;st.tl.z=9;s.field.add(st.tl);st.cap=label('FINDE ZWEI ZAHLEN MIT DER SUMME',11,white(1,.65));st.cap.y=p.cy+p.h/2-16;st.cap.z=9;s.field.add(st.cap);this.fill(st);return st})}
 fill(st){const v=[];for(let i=0;i<6;i++)v.push(1+Math.floor(Math.random()*14));const a=Math.floor(Math.random()*6);let b=Math.floor(Math.random()*6);while(b===a)b=Math.floor(Math.random()*6);st.T=v[a]+v[b];st.vals=v;st.sel=-1;st.tl.text='= '+st.T;st.cells.forEach((q,i)=>{q.l.text=''+v[i];q.c.color=white(1,.14)});st.cpu=NK.rr(1.4,2.4)}
 gameUpdate(dt){for(const s of this.seats){if(!s.isCPU)continue;const st=this.st[s.index];st.cpu-=dt*(.6+s.skill*.9);if(st.cpu<=0){st.cpu=NK.rr(1.4,2.2);const pr=[];for(let i=0;i<6;i++)for(let j=i+1;j<6;j++)if(st.vals[i]+st.vals[j]===st.T)pr.push([i,j]);if(Math.random()<.8+s.skill*.18&&pr.length){const q=pr[0];this.tap(s,q[0]);this.tap(s,q[1])}else{this.tap(s,0);this.tap(s,1)}}}}
 began(s,at){const st=this.st[s.index];let b=-1;st.cells.forEach((q,i)=>{if(Math.abs(q.x-at.x)<st.cw/2&&Math.abs(q.y-at.y)<st.ch/2)b=i});if(b>=0)this.tap(s,b)}
 tap(s,i){const st=this.st[s.index],q=st.cells[i];if(st.sel===i){st.sel=-1;q.c.color=white(1,.14);return}
  if(st.sel<0){st.sel=i;q.c.color=NK.al(s.color,.55);Sfx.play('tap');return}
  const j=st.sel;st.sel=-1;const sum=st.vals[i]+st.vals[j],pos={x:(q.x+st.cells[j].x)/2,y:(q.y+st.cells[j].y)/2};
  if(sum===st.T){this.addScore(s,1);this.addStat('hits',1,s);s.floatText('+1',pos,'#ff0',24);s.burst(pos,s.color,12,110);NK.ring(s,pos,s.color,14);Sfx.play('right');if(!s.isCPU)Haptic.tap('light');this.fill(st)}
  else{this.addScore(s,-1);s.floatText('−1',pos,'#f44',22);s.flash('#f00',.2);Sfx.play('wrong');st.cells[j].c.color=white(1,.14);q.c.color=white(1,.14);st.cells[j].c.run(A.sequence([A.moveBy(4,0,.04),A.moveBy(-8,0,.06),A.moveBy(4,0,.04)]))}}
}
Arcade.register('target',TargetGame);})();
