(()=>{const {Node,Sprite,A,Gfx,rgba,white,label}=SK;
window.NK={
 al:(c,a)=>c.replace(/[\d.]+\)$/,a+')'),
 rr:(a,b)=>a+Math.random()*(b-a),
 pf(s){return{w:s.w-16,h:s.h-80,cy:-6}},
 panel(s,col){const p=NK.pf(s),sp=new Sprite(Gfx.pill(p.w,p.h,'rgba(10,12,26,.55)',NK.al(col,.4),22,false),p.w,p.h);sp.y=p.cy;sp.z=-5;s.field.add(sp);const g=new Sprite(Gfx.glow(),p.w*1.2,p.h*1.1);g.color=col;g.cbf=1;g.blend='add';g.alpha=.1;g.y=p.cy;g.z=-6;s.field.add(g);return p},
 ring(s,pos,col,r,dur){const g=new Sprite(Gfx.circle(r||14,'rgba(0,0,0,0)',col),(r||14)*2,(r||14)*2);g.blend='add';g.x=pos.x;g.y=pos.y;g.z=50;s.field.add(g);g.run(A.sequence([A.group([A.scaleTo(3,dur||.35),A.fadeOut(dur||.35)]),A.remove()]))},
 dot(s,col,w,z){const d=new Sprite(Gfx.dot(),w,w);d.color=col;d.cbf=1;d.blend='add';d.z=z||10;s.field.add(d);return d},
 clamp:(v,a,b)=>Math.max(a,Math.min(b,v))
};})();
